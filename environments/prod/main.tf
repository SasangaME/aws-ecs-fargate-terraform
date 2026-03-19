terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "network" {
  source             = "../../modules/network"
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

module "ecs_cluster" {
  source       = "../../modules/ecs-cluster"
  environment  = var.environment
  cluster_name = "fargate-cluster"
}

module "alb" {
  source         = "../../modules/alb"
  environment    = var.environment
  vpc_id         = module.network.vpc_id
  public_subnets = module.network.public_subnets
}

module "iam" {
  source      = "../../modules/iam"
  environment = var.environment
}

module "ecs_service" {
  source                = "../../modules/ecs-service"
  environment           = var.environment
  cluster_id            = module.ecs_cluster.cluster_id
  vpc_id                = module.network.vpc_id
  private_subnets       = module.network.private_subnets
  alb_security_group_id = module.alb.security_group_id
  listener_arn          = module.alb.listener_arn
  execution_role_arn    = module.iam.execution_role_arn
  task_role_arn         = module.iam.task_role_arn
  container_image       = "public.ecr.aws/docker/library/httpd:latest"
  container_port        = 80
  
  # Pass Production scale-up values
  desired_count = var.desired_count
  cpu           = var.cpu
  memory        = var.memory
}
