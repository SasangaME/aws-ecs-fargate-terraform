terraform {
  backend "s3" {
    bucket         = "ecs-fargate-terraform-state"
    key            = "ecs-fargate/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
