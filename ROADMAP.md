# Roadmap: Production Readiness

Tracked improvements required before this infrastructure is production-grade. Items are ordered by priority within each tier.

## Critical

- [x] **HTTPS/TLS on ALB** — Add ACM certificate and HTTPS listener (port 443), redirect HTTP to HTTPS
- [ ] **Route53 DNS** — Add hosted zone and alias records pointing to the ALB
- [ ] **CloudWatch Alarms** — Alarms for unhealthy targets, task count drift, high CPU/memory, NAT errors
- [ ] **SNS Notifications** — SNS topic for alarm delivery to ops team (email, Slack, PagerDuty)
- [ ] **WAF on ALB** — AWS WAFv2 web ACL with managed rule groups (core, SQL injection, XSS)
- [ ] **VPC Flow Logs** — Enable flow logs to CloudWatch or S3 for network audit trail

## Important

- [ ] **Auto-scaling** — Application Auto Scaling with target tracking on CPU/memory for the ECS service
- [ ] **Deployment circuit breaker** — Enable `deployment_circuit_breaker` with rollback on the ECS service
- [ ] **Deployment configuration** — Set explicit `minimum_healthy_percent`, `maximum_percent`, and `health_check_grace_period_seconds`
- [ ] **Restrict task egress** — Tighten ECS task security group outbound rules to only required destinations
- [ ] **VPC endpoints** — Add gateway/interface endpoints for ECR, S3, and CloudWatch to reduce NAT costs and latency
- [ ] **ALB access logs** — Enable access logging to S3 with a retention policy
- [ ] **ECS Exec** — Enable `enable_execute_command` on the ECS service for container debugging
- [ ] **Secrets Manager integration** — Add IAM permissions and task definition support for injecting secrets
- [ ] **Pin container images** — Use SHA256 digests instead of mutable tags in production

## Nice-to-Have

- [ ] **CloudWatch dashboards** — Consolidated dashboard for ALB, ECS, and NAT metrics
- [ ] **Blue-green deployments** — CodeDeploy integration for zero-downtime releases
- [ ] **Variable validation** — Add `validation` blocks to enforce valid Fargate CPU/memory combinations
- [ ] **Cost allocation tags** — Add `Owner`, `Team`, and `CostCenter` tags at the provider level
- [ ] **S3 lifecycle rules** — Expire old state file versions after 90 days
- [ ] **Cross-region state backup** — S3 replication for the Terraform state bucket
- [ ] **Fargate Spot for dev/staging** — Switch non-prod environments to `FARGATE_SPOT` capacity provider
