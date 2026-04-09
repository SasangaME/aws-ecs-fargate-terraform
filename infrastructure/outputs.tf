output "vpc_id" {
  value = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "ecs_execution_role_arn" {
  value = module.iam.execution_role_arn
}

output "service_name" {
  value = module.ecs_service.service_name
}

output "acm_certificate_arn" {
  value = module.alb.acm_certificate_arn
}

output "acm_domain_validation_options" {
  description = "Add these DNS records to validate the ACM certificate"
  value       = module.alb.acm_domain_validation_options
}
