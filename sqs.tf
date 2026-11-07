resource "aws_sqs_queue" "dlq" {
  name                       = "${var.project}-ingestion-dlq"
  message_retention_seconds  = 1209600  # 14 days
  visibility_timeout_seconds = 300
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.project}-ingestion"
  visibility_timeout_seconds = 300
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 345600   # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}