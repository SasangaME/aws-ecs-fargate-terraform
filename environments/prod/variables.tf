variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnet CIDRs"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "private_subnets" {
  description = "A list of private subnet CIDRs"
  type        = list(string)
  default     = ["10.2.3.0/24", "10.2.4.0/24"]
}

variable "availability_zones" {
  description = "A list of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Higher defaults for Production
variable "desired_count" {
  description = "Baseline number of Production tasks"
  type        = number
  default     = 3
}

variable "cpu" {
  description = "Production Fargate CPU (larger units)"
  type        = string
  default     = "512" # Overrides dev/staging defaults of 256
}

variable "memory" {
  description = "Production memory"
  type        = string
  default     = "1024" # Overrides dev/staging defaults of 512
}
