variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "A list of availability zones"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (true for cost savings, false for HA)"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "fargate-cluster"
}

variable "container_image" {
  description = "Docker image URI for the ECS task"
  type        = string
  default     = "public.ecr.aws/docker/library/httpd:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "Fargate CPU units (e.g., 256, 512, 1024)"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Fargate memory in MB (e.g., 512, 1024, 2048)"
  type        = string
  default     = "512"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "listener_rule_priority" {
  description = "Priority for the ALB listener rule (unique per listener)"
  type        = number
  default     = 100
}

variable "domain_name" {
  description = "Domain name for ACM certificate and HTTPS listener. Leave empty to use HTTP only."
  type        = string
  default     = ""
}
