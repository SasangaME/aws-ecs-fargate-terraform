# Operational Runbook: AWS ECS Fargate Infrastructure

This runbook contains standard operating procedures for deploying, updating, scaling, and troubleshooting the ECS Fargate Terraform infrastructure.

For architecture, design decisions, and how the codebase works, see [README.md](README.md).

---

## Prerequisites

Install [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/):

```bash
# macOS
brew install terragrunt

# Verify installation
terragrunt --version
```

---

## 1. Initial Deployment (New Environment)

To spin up a new environment (e.g., `dev`):

1. **Bootstrap remote state** (first time only):
   ```bash
   cd bootstrap
   terraform init && terraform apply
   ```

2. **Navigate to the environment directory:**
   ```bash
   cd live/dev
   ```

3. **Review the environment inputs:**
   Open `terragrunt.hcl` and verify the inputs (VPC CIDR, subnets, etc.) are correct for your deployment.

4. **Initialize and review the execution plan:**
   ```bash
   terragrunt init
   terragrunt plan
   ```

5. **Apply the changes:**
   ```bash
   terragrunt apply
   ```

### Deploy All Environments at Once

From the `live/` directory, Terragrunt can deploy all environments in parallel:

```bash
cd live
terragrunt run-all apply
```

---

## 2. Pushing App Updates (Container Updates)

When you have a new Docker image version or tag (e.g., from `v1.0` to `v1.2`):

1. Update the `container_image` input in `live/<env>/terragrunt.hcl`.
2. Run `terragrunt plan` to verify that only the Task Definition and Service are being updated.
3. Run `terragrunt apply`. ECS will perform a **rolling update** automatically by spawning new tasks before shutting down old ones.

---

## 3. Scaling the Application

If you need to handle more traffic:

1. Open `live/<env>/terragrunt.hcl`.
2. Add or update `desired_count` in the `inputs` block (e.g., from `2` to `5`).
3. Run `terragrunt plan` and `terragrunt apply`. ECS Fargate will immediately begin provisioning the additional tasks.

**Emergency scaling** (skip Terraform for immediate effect):
```bash
aws ecs update-service --cluster <env>-fargate-cluster \
  --service <env>-service --desired-count 5
```
> **Note:** This creates drift between Terraform state and AWS. Run `terraform apply` afterwards to reconcile.

---

## 4. Managing the `environment` Variable

The `environment` variable is used to prefix resource names and tag items (e.g., `dev-ecs-task-role`). With Terragrunt, this is set in each environment's `terragrunt.hcl` inputs block:

```hcl
# live/dev/terragrunt.hcl
inputs = {
  environment = "dev"
  # ...
}
```

You can still override via the command line if needed:

```bash
cd live/dev
terragrunt apply -var="environment=dev-hotfix"
```

---

## 5. Enabling HTTPS/TLS

To enable HTTPS on the ALB, you need a domain name. The module creates an ACM certificate, an HTTPS listener (port 443), and redirects all HTTP traffic to HTTPS.

### Steps

1. **Set `domain_name` in your environment config:**
   ```hcl
   # live/prod/terragrunt.hcl
   inputs = {
     domain_name = "app.example.com"
     # ... other inputs
   }
   ```

2. **Apply the changes:**
   ```bash
   cd live/prod
   terragrunt plan    # Verify: ACM certificate, HTTPS listener, HTTP redirect
   terragrunt apply
   ```

3. **Validate the ACM certificate via DNS:**

   After apply, Terraform outputs the DNS validation records:
   ```bash
   terragrunt output acm_domain_validation_options
   ```
   Add the CNAME record shown in the output to your DNS provider (e.g., Route 53, Cloudflare). ACM will automatically validate and activate the certificate once the record propagates.

4. **Verify HTTPS is working:**
   ```bash
   # Should return 301 redirect to HTTPS
   curl -I http://app.example.com

   # Should return 200 (once cert is validated)
   curl -I https://app.example.com
   ```

### Notes

- The ACM certificate uses **DNS validation** (recommended over email validation for automation).
- The HTTPS listener uses the `ELBSecurityPolicy-TLS13-1-2-2021-06` SSL policy, which enforces TLS 1.2+ with TLS 1.3 support.
- ACM certificates in `us-east-1` are free. There is no additional cost for HTTPS on ALB beyond the existing ALB charges.
- If `domain_name` is left empty (default), the ALB operates in HTTP-only mode with no changes to existing behavior.

---

## 6. Disaster Recovery & Teardown

To completely remove an environment and stop all AWS costs:
```bash
cd live/<env>
terragrunt destroy
```

To tear down all environments:
```bash
cd live
terragrunt run-all destroy
```

Before running `terragrunt destroy` in production:
1. Confirm there are no active users or dependent services.
2. Take a final backup of any application data (ECS tasks are stateless, but verify).
3. Notify the team — this removes the VPC, ALB, NAT Gateway, and all ECS resources.

---

## 7. Monitoring & Observability

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
cd live/<env>
terragrunt output

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

---

## 8. Troubleshooting

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

1. **Check target health** (see Section 7).
2. **Verify security groups:** The ALB security group must allow inbound traffic on port 80, and the ECS task security group must allow inbound from the ALB security group on the container port.
3. **Check container logs** for application errors.

### Terraform state lock errors

If a previous `terragrunt apply` was interrupted:

```bash
# Check who holds the lock
cd live/<env>
terragrunt force-unlock <LOCK_ID>
```

> Only use `force-unlock` if you're certain no other apply is running.

### High NAT Gateway costs

If NAT data processing charges are unexpectedly high:
- Check which tasks are generating outbound traffic: **VPC Flow Logs** or **CloudWatch Container Insights**.
- Add **VPC Endpoints** for S3, ECR, and CloudWatch to route traffic privately instead of through the NAT Gateway. This eliminates the $0.045/GB NAT data charge for those services.

---

## 9. Security & Maintenance

- **IAM Rotation**: Use the `modules/iam` module to rotate credentials or tighten permissions (Principle of Least Privilege).
- **Log Inspection**: Use the CloudWatch Log Group defined in the `ecs-service` module to investigate application errors or performance bottlenecks.
- **VPC Flow Logs**: Enable flow logs in `modules/network` if you need to debug network connectivity issues between AWS services.
- **Container Image Updates**: Regularly update base images to patch OS-level vulnerabilities. Pin to specific image tags (not `latest`) in production.
- **Terraform Provider Updates**: Periodically update the AWS provider version in `versions.tf` files to pick up bug fixes and new features. Test in dev first.
