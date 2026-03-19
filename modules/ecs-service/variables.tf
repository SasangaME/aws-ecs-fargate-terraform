variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "cluster_id" {
  description = "The ID of the ECS Cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnets for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS Execution Role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS Task Role"
  type        = string
}

variable "container_name" {
  description = "Name for the container"
  type        = string
  default     = "web-app"
}

variable "container_image" {
  description = "The Docker image URI to use"
  type        = string
  default     = "public.ecr.aws/docker/library/httpd:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Number of tasks to keep running"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "Fargate CPU units (e.g., 256, 512, 1024)"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Fargate memory units (e.g., 512, 1024, 2048)"
  type        = string
  default     = "512"
}

variable "listener_arn" {
  description = "The ARN of the ALB Listener"
  type        = string
}
