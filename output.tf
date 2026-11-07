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