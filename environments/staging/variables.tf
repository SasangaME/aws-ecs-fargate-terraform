variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  default     = "staging"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnet CIDRs"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnets" {
  description = "A list of private subnet CIDRs"
  type        = list(string)
  default     = ["10.1.3.0/24", "10.1.4.0/24"]
}

variable "availability_zones" {
  description = "A list of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
