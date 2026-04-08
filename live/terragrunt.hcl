# Root Terragrunt configuration
# Common settings inherited by all environments

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "ecs-fargate-terraform-state"
    key            = "ecs-fargate/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

terraform {
  source = "${get_repo_root()}/infrastructure"
}
