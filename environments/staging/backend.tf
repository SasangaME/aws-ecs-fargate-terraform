# --- Use this to migrate from local state to S3 ---
/*
terraform {
  backend "s3" {
    bucket         = "YOUR-TERRAFORM-STATE-BUCKET"
    key            = "ecs-fargate/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
*/
