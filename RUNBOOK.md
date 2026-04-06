# Operational Runbook: AWS ECS Fargate Infrastructure

This runbook provide standard operating procedures for the ECS Fargate Terraform infrastructure.

## 1. Initial Deployment (New Environment)
To spin up a new environment (e.g., `dev`):

1. **Navigate to the environment directory:**
   ```bash
   cd environments/dev
   ```

2. **Initialize the workspace:**
   ```bash
   terraform init
   ```

3. **Review the execution plan:**
   Always run a plan to see exactly what AWS resources will be created. 
   Verify the ARNs of any Load Balancers or VPC IDs are correct.
   ```bash
   terraform plan -out=tfplan
   ```

4. **Apply the changes:**
   ```bash
   terraform apply "tfplan"
   ```

## 2. Pushing App Updates (Container Updates)
When you have a new Docker image version or tag (e.g., from `v1.0` to `v1.2`):
1. Update the `container_image` variable in your `terraform.tfvars` or `main.tf`.
2. Run `terraform plan` to verify that only the Task Definition and Service are being updated.
3. Run `terraform apply`. ECS will perform a **rolling update** automatically by spawning new tasks before shutting down old ones.

## 3. Scaling the Application
If you need to handle more traffic:
1. Go to `environments/<env>/main.tf`.
2. Locate the `ecs_service` module instantiation.
3. Update `desired_count` (e.g., from `2` to `5`).
4. Apply the changes. ECS Fargate will immediately begin provisioning the additional tasks.

## 4. Disaster Recovery & Teardown
To completely remove an environment and stop all AWS costs:
```bash
terraform destroy
```

## 5. Compute Strategy: Fargate vs EC2 vs Fargate Spot

This section explains the three compute options available for ECS and when to use each, based on the cost and operational characteristics of this project.

### How ECS compute works

The `aws_ecs_cluster` resource is a **logical namespace only** — it has no compute attached. What determines where your containers actually run is declared in the ECS Service and Task Definition inside `modules/ecs-service/main.tf`:

```hcl
# Task Definition — declares Fargate as required
requires_compatibilities = ["FARGATE"]
network_mode             = "awsvpc"

# ECS Service — launches tasks on Fargate
launch_type = "FARGATE"
```

You can switch compute strategies by changing these two blocks. No changes to the cluster, VPC, or ALB are needed.

---

### Option 1: Fargate (current)

AWS provisions a micro-VM for each task. You never see or manage the underlying host.

**How it works:**
- You define CPU units and memory in the Task Definition
- AWS finds capacity, starts your container, and keeps it running
- If a task crashes, ECS automatically replaces it
- Tasks run 24/7 — they are not event-driven (unlike Lambda)

**This is not Lambda.** Fargate is a long-running container (like a traditional server process). Lambda is a short-lived function that exits after handling one event. Fargate is appropriate for web APIs, background workers, and microservices that need to be always-on.

**Cost (us-east-1, 730 hrs/month):**

| Environment | Tasks | vCPU | Memory | Monthly compute |
|-------------|-------|------|--------|----------------|
| Dev | 2 | 0.25 each | 512 MB each | ~$18 |
| Staging | 2 | 0.25 each | 512 MB each | ~$18 |
| Prod | 3 | 0.5 each | 1 GB each | ~$54 |

Pricing rates: `$0.04048/vCPU-hr` + `$0.004445/GB-hr`

**Pros:** Zero infrastructure management, no patching, scales per-task, HA by default.
**Cons:** More expensive than EC2 for large sustained workloads.

---

### Option 2: EC2 launch type

You provision EC2 instances that register as ECS Container Instances. ECS schedules tasks onto them.

**How it works:**
- You create an Auto Scaling Group of EC2 instances with the ECS-optimized AMI
- The ECS agent runs on each instance and reports available CPU/memory
- ECS bins-packs tasks onto instances
- You are responsible for: instance patching, ECS agent updates, ASG scaling policies, and capacity planning

**Minimum instance sizes for this project:**

| Environment | Total needed (tasks + agent overhead) | Recommended instance | On-Demand/mo |
|-------------|--------------------------------------|---------------------|-------------|
| Dev/Staging | ~0.6 vCPU, ~1.1 GB | t3.small (2 vCPU, 2 GB) | $15 |
| Prod | ~1.6 vCPU, ~3.1 GB | t3.medium (2 vCPU, 4 GB) or 2× t3.small | $30 |

**Cost comparison vs Fargate:**

| | Fargate | EC2 on-demand | EC2 1yr reserved |
|--|---------|--------------|-----------------|
| Dev compute | $18/mo | $15/mo | ~$9/mo |
| Prod compute | $54/mo | $30/mo | ~$18/mo |
| Manage OS/patching | No | Yes | Yes |
| Requires ASG + Launch Template | No | Yes | Yes |

**Verdict:** EC2 saves $3–9/mo in dev (not worth the overhead) and $24–36/mo in prod (worth considering if you have DevOps capacity to manage it). For most teams running this project, the operational cost of managing EC2 instances outweighs the savings at this task scale.

**Additional Terraform required for EC2 mode:**
```hcl
# You would need to add to environments/<env>/main.tf:
resource "aws_autoscaling_group" "ecs" { ... }
resource "aws_launch_template" "ecs" { ... }
resource "aws_ecs_capacity_provider" "ec2" { ... }
```

---

### Option 3: Fargate Spot (recommended for dev/staging)

Fargate Spot runs your tasks on spare AWS capacity at up to **70% discount**. AWS may reclaim tasks with a 2-minute warning when it needs capacity back (rare in practice).

**How it works:**
- Identical to standard Fargate — no infrastructure to manage
- AWS sends a `SIGTERM` to your container 2 minutes before reclaiming it
- ECS automatically replaces interrupted tasks
- Best used alongside at least 1 standard Fargate task in prod for guaranteed availability

**Cost comparison:**

| Environment | Standard Fargate | Fargate Spot | Saving |
|-------------|-----------------|-------------|--------|
| Dev compute | $18/mo | ~$5/mo | ~$13/mo |
| Staging compute | $18/mo | ~$5/mo | ~$13/mo |
| Prod compute | $54/mo | ~$16/mo | ~$38/mo |

**To enable Fargate Spot**, replace `launch_type` in `modules/ecs-service/main.tf` with a capacity provider strategy:

```hcl
# Remove this:
# launch_type = "FARGATE"

# Add this (100% Spot — suitable for dev/staging):
capacity_provider_strategy {
  capacity_provider = "FARGATE_SPOT"
  weight            = 1
}
```

For **prod**, use a mixed strategy to guarantee at least one task survives a Spot reclamation:

```hcl
# 1 task always on standard Fargate, rest on Spot:
capacity_provider_strategy {
  capacity_provider = "FARGATE"
  weight            = 1
  base              = 1
}

capacity_provider_strategy {
  capacity_provider = "FARGATE_SPOT"
  weight            = 3
}
```

**Important:** When using `capacity_provider_strategy`, the cluster must have the providers enabled. Add this to `modules/ecs-cluster/main.tf`:

```hcl
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
}
```

---

### Decision guide

```
Are you running dev or staging?
  └── Yes → Use Fargate Spot (70% cheaper, zero management)

Are you running prod?
  ├── Small scale (< 5 tasks) → Use Fargate or mixed Fargate + Spot
  ├── Medium scale (5–20 tasks) → Evaluate mixed Spot strategy
  └── Large scale (20+ tasks, sustained) → Consider EC2 with reserved instances

Do you have time to manage EC2 instances, patching, and ASG tuning?
  └── No → Stay on Fargate or Fargate Spot regardless of environment
```

---

### Additional cost-saving tips

- **Scale to zero at night (dev only):** Use AWS EventBridge Scheduler to set `desired_count = 0` outside business hours. Fargate tasks have no idle cost when not running.
  ```bash
  aws ecs update-service --cluster dev-fargate-cluster \
    --service dev-service --desired-count 0
  ```
- **Use VPC Endpoints:** Traffic from ECS to S3, ECR, and CloudWatch routed through a NAT Gateway costs $0.045/GB. VPC Endpoints eliminate that cost entirely for supported services.
- **Rightsize before scaling:** Check CloudWatch Container Insights metrics. If CPU utilization is consistently below 20%, halve the `cpu` allocation before adding more tasks.

---

## 6. Security & Maintenance
*   **IAM Rotation**: Use the `modules/iam` module to rotate credentials or tighten permissions (Principle of Least Privilege).
*   **Log Inspection**: Use the CloudWatch Log Group defined in the `ecs-service` module to investigate application errors or performance bottlenecks.
*   **VPC Flow Logs**: Check the `modules/network` module to enable flow logs if you need to debug network connectivity issues between AWS services.
