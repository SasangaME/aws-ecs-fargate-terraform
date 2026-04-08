include "root" {
  path = find_in_parent_folders()
}

inputs = {
  aws_region         = "us-east-1"
  environment        = "staging"
  vpc_cidr           = "10.1.0.0/16"
  public_subnets     = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets    = ["10.1.3.0/24", "10.1.4.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
  single_nat_gateway = true
  log_retention_days = 14
}
