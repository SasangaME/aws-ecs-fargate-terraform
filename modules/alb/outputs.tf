output "alb_id" {
  value = aws_lb.main.id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "security_group_id" {
  value = aws_security_group.alb.id
}

output "listener_arn" {
  description = "ARN of the active listener (HTTPS if domain_name is set, otherwise HTTP)"
  value       = var.domain_name != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate (empty if HTTPS is not enabled)"
  value       = var.domain_name != "" ? aws_acm_certificate.main[0].arn : ""
}

output "acm_domain_validation_options" {
  description = "DNS validation records needed for the ACM certificate"
  value       = var.domain_name != "" ? aws_acm_certificate.main[0].domain_validation_options : []
}
