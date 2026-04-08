# Operational Runbook: AWS ECS Fargate Infrastructure

This runbook contains standard operating procedures for deploying, updating, scaling, and troubleshooting the ECS Fargate Terraform infrastructure.

For architecture, design decisions, and how the codebase works, see [README.md](README.md).

---

## 1. Initial Deployment (New Environment)

To spin up a new environment (e.g., `dev`):

1. **Navigate to the environment directory:**
   ```bash
   cd environments/dev
   ```

2. **Copy and configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize the workspace:**
   ```bash
   terraform init
   ```

4. **Review the execution plan:**
   Always run a plan to see exactly what AWS resources will be created.
   Verify the ARNs of any Load Balancers or VPC IDs are correct.
   ```bash
   terraform plan -out=tfplan
   ```

5. **Apply the changes:**
   ```bash
   terraform apply "tfplan"
   ```

---

## 2. Pushing App Updates (Container Updates)

When you have a new Docker image version or tag (e.g., from `v1.0` to `v1.2`):

1. Update the `container_image` variable in your `terraform.tfvars`.
2. Run `terraform plan` to verify that only the Task Definition and Service are being updated.
3. Run `terraform apply`. ECS will perform a **rolling update** automatically by spawning new tasks before shutting down old ones.

---

## 3. Scaling the Application

If you need to handle more traffic:

1. Go to `environments/<env>/terraform.tfvars`.
2. Update `desired_count` (e.g., from `2` to `5`).
3. Run `terraform plan` and `terraform apply`. ECS Fargate will immediately begin provisioning the additional tasks.

**Emergency scaling** (skip Terraform for immediate effect):
```bash
aws ecs update-service --cluster <env>-fargate-cluster \
  --service <env>-service --desired-count 5
```
> **Note:** This creates drift between Terraform state and AWS. Run `terraform apply` afterwards to reconcile.

---

## 4. Managing the `environment` Variable

The `environment` variable is used to prefix resource names and tag items (e.g., `dev-ecs-task-role`). There are several ways to provide or override this value:

- **Folder-specific Defaults**: Each environment folder (`environments/dev`, `environments/prod`, etc.) already has a default value defined in its `variables.tf`.
- **Using `.tfvars` file (Recommended)**: Create or edit `terraform.tfvars` within the environment directory:
  ```hcl
  environment = "dev"
  ```
- **Command Line override**:
  ```bash
  terraform apply -var="environment=dev"
  ```
- **Environment Variable**:
  ```bash
  export TF_VAR_environment="dev"
  terraform apply
  ```

---

## 5. Disaster Recovery & Teardown

To completely remove an environment and stop all AWS costs:
```bash
cd environments/<env>
terraform destroy
```

Before running `terraform destroy` in production:
1. Confirm there are no active users or dependent services.
2. Take a final backup of any application data (ECS tasks are stateless, but verify).
3. Notify the team — this removes the VPC, ALB, NAT Gateway, and all ECS resources.

---

## 6. Monitoring & Observability

### CloudWatch Logs

Each ECS service writes container logs to a CloudWatch Log Group. To view logs:

```bash
# Find the log group
aws logs describe-log-groups --log-group-name-prefix "/ecs/<env>"

# Tail recent logs
aws logs tail "/ecs/<env>-service" --follow
```

### Container Insights

Container Insights is enabled on the ECS cluster by default. Check cluster-level metrics (CPU, memory, task count) in the CloudWatch console under **Container Insights > ECS**.

### ALB Health Checks

The ALB target group performs health checks against your container. To check target health:

```bash
# Get the target group ARN from Terraform output
cd environments/<env>
terraform output

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

---

## 7. Troubleshooting

### Tasks failing to start

**Symptoms:** Tasks cycle between `PENDING` and `STOPPED`, never reaching `RUNNING`.

1. **Check stopped task reason:**
   ```bash
   aws ecs describe-tasks --cluster <env>-fargate-cluster \
     --tasks $(aws ecs list-tasks --cluster <env>-fargate-cluster \
     --desired-status STOPPED --query 'taskArns[0]' --output text)
   ```
   Look at the `stoppedReason` and `containers[].reason` fields.

2. **Common causes:**
   - **"CannotPullContainerError"** — Image doesn't exist or tasks can't reach ECR/Docker Hub. Verify the NAT Gateway is running and the image URI is correct.
   - **"ResourceInitializationError"** — Usually a networking issue. Confirm private subnets have a route to the NAT Gateway.
   - **"OutOfMemoryError"** — Container exceeded the memory limit in the Task Definition. Increase `memory` in `terraform.tfvars`.

### Tasks running but ALB returns 502/503

1. **Check target health** (see Section 6).
2. **Verify security groups:** The ALB security group must allow inbound traffic on port 80, and the ECS task security group must allow inbound from the ALB security group on the container port.
3. **Check container logs** for application errors.

### Terraform state lock errors

If a previous `terraform apply` was interrupted:

```bash
# Check who holds the lock
terraform force-unlock <LOCK_ID>
```

> Only use `force-unlock` if you're certain no other apply is running.

### High NAT Gateway costs

If NAT data processing charges are unexpectedly high:
- Check which tasks are generating outbound traffic: **VPC Flow Logs** or **CloudWatch Container Insights**.
- Add **VPC Endpoints** for S3, ECR, and CloudWatch to route traffic privately instead of through the NAT Gateway. This eliminates the $0.045/GB NAT data charge for those services.

---

## 8. Security & Maintenance

- **IAM Rotation**: Use the `modules/iam` module to rotate credentials or tighten permissions (Principle of Least Privilege).
- **Log Inspection**: Use the CloudWatch Log Group defined in the `ecs-service` module to investigate application errors or performance bottlenecks.
- **VPC Flow Logs**: Enable flow logs in `modules/network` if you need to debug network connectivity issues between AWS services.
- **Container Image Updates**: Regularly update base images to patch OS-level vulnerabilities. Pin to specific image tags (not `latest`) in production.
- **Terraform Provider Updates**: Periodically update the AWS provider version in `versions.tf` files to pick up bug fixes and new features. Test in dev first.
