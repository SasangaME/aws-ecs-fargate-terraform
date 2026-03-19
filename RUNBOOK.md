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

## 5. Security & Maintenance
*   **IAM Rotation**: Use the `modules/iam` module to rotate credentials or tighten permissions (Principle of Least Privilege).
*   **Log Inspection**: Use the CloudWatch Log Group defined in the `ecs-service` module to investigate application errors or performance bottlenecks.
*   **VPC Flow Logs**: Check the `modules/network` module to enable flow logs if you need to debug network connectivity issues between AWS services.
