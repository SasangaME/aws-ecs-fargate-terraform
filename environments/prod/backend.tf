# --- Use this for production state storage ---
/*
terraform {
  backend "s3" {
    bucket         = "PROD-TERRAFORM-STATE-BUCKET"
    key            = "ecs-fargate/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
*/
