include "root" {
  path = find_in_parent_folders()
}

inputs = {
  aws_region         = "us-east-1"
  environment        = "prod"
  vpc_cidr           = "10.2.0.0/16"
  public_subnets     = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnets    = ["10.2.3.0/24", "10.2.4.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
  single_nat_gateway = false
  desired_count      = 3
  cpu                = "512"
  memory             = "1024"
  log_retention_days = 30
}
