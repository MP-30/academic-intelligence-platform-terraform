output "rds_endpoint" {
  description = "RDS Postgres endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "rds_host" {
  description = "RDS Postgres host"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  value = aws_db_instance.main.port
}

output "rds_db_name" {
  value = var.db_name
}

output "rds_username" {
  value = var.db_username
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}

output "s3_bucket" {
  description = "S3 bucket for PDF uploads"
  value       = aws_s3_bucket.docs.id
}

output "sqs_queue_url" {
  description = "Main SQS ingestion queue URL"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.main.arn
}

output "sqs_dlq_url" {
  description = "SQS dead-letter queue URL"
  value       = aws_sqs_queue.dlq.url
}

output "database_url_asyncpg" {
  description = "Full asyncpg URL for .env"
  value       = "postgresql+asyncpg://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"
  sensitive   = true
}

output "database_url_psycopg" {
  description = "Full psycopg URL for worker"
  value       = "postgresql+psycopg://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"
  sensitive   = true
}

output "ecr_repository_url" {
  value = aws_ecr_repository.worker.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = var.ecs_worker_enabled ? aws_ecs_service.worker[0].name : "not-enabled"
}

output "ui_url" {
  value = "https://${var.ui_subdomain}.${var.domain_name}"
}

output "api_url" {
  value = "https://${var.api_subdomain}.${var.domain_name}"
}

output "alb_dns" {
  value = aws_lb.main.dns_name
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.api.id
}

output "acm_validation_records" {
  description = "Add these CNAMEs at Namify to validate the ACM cert"
  value = [
    for opt in aws_acm_certificate.main.domain_validation_options : {
      host  = replace(opt.resource_record_name, ".${var.domain_name}.", "")
      value = opt.resource_record_value
    }
  ]
}

output "subdomain_records" {
  description = "Add these CNAMEs at Namify after apply completes"
  value = {
    ui  = { host = var.ui_subdomain,  target = aws_lb.main.dns_name }
    api = { host = var.api_subdomain, target = aws_lb.main.dns_name }
  }
}