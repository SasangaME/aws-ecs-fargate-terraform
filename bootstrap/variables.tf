variable "aws_region" {
  description = "AWS region where the state bucket and lock table will be created"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform remote state (must be globally unique)"
  type        = string
  default     = "ecs-fargate-terraform-state"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-lock-table"
}
