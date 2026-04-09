variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnets for the ALB"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for ACM certificate and HTTPS listener. Leave empty to use HTTP only."
  type        = string
  default     = ""
}
