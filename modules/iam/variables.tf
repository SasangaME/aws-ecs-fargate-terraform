variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "fargate-app"
}
