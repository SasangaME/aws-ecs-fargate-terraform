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
