data "aws_iam_user" "bedrock_dev" {
  user_name = var.bedrock_dev_user
}

resource "aws_iam_policy" "runtime_access" {
  name        = "${var.project}-runtime-access"
  description = "S3 + SQS access for academic-rag application runtime"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3DocumentAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.docs.arn,
          "${aws_s3_bucket.docs.arn}/*",
        ]
      },
      {
        Sid    = "SQSIngestionAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueUrl",
        ]
        Resource = [
          aws_sqs_queue.main.arn,
          aws_sqs_queue.dlq.arn,
        ]
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "bedrock_dev_runtime" {
  user       = data.aws_iam_user.bedrock_dev.user_name
  policy_arn = aws_iam_policy.runtime_access.arn
}