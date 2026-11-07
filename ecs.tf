resource "aws_ecs_cluster" "main" {
  name = "${var.project}"
}

resource "aws_cloudwatch_log_group" "ecs_worker" {
  name              = "/ecs/${var.project}-worker"
  retention_in_days = 7
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.project}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy" "ecs_task" {
  name = "${var.project}-ecs-task"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [aws_s3_bucket.docs.arn, "${aws_s3_bucket.docs.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage", "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes", "sqs:GetQueueUrl",
        ]
        Resource = [aws_sqs_queue.main.arn, aws_sqs_queue.dlq.arn]
      },
    ]
  })
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project}-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "worker"
    image     = "${aws_ecr_repository.worker.repository_url}:latest"
    essential = true

    environment = [
      { name = "DATABASE_URL", value = "postgresql+psycopg://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}?sslmode=require" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "AWS_DEFAULT_REGION", value = var.aws_region },
      { name = "S3_ENDPOINT_URL", value = "" },
      { name = "SQS_ENDPOINT_URL", value = "" },
      { name = "S3_BUCKET", value = aws_s3_bucket.docs.id },
      { name = "SQS_QUEUE_NAME", value = aws_sqs_queue.main.name },
      { name = "SQS_QUEUE_URL", value = aws_sqs_queue.main.url },
      { name = "EMBEDDING_PROVIDER", value = "bedrock" },
      { name = "EMBEDDING_MODEL_ID", value = "amazon.titan-embed-text-v2:0" },
      { name = "EMBEDDING_DIMENSIONS", value = "1024" },
      { name = "CHUNK_SIZE_TOKENS", value = "600" },
      { name = "CHUNK_OVERLAP_TOKENS", value = "100" },
      { name = "INGESTION_VISIBILITY_SECONDS", value = "300" },
      { name = "INGESTION_MAX_RETRIES", value = "5" },
      { name = "POSTGRES_USER", value = var.db_username },
      { name = "POSTGRES_PASSWORD", value = var.db_password },
      { name = "POSTGRES_DB", value = var.db_name },
      { name = "POSTGRES_PORT", value = tostring(aws_db_instance.main.port) },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_worker.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "worker"
      }
    }
  }])
}

resource "aws_ecs_service" "worker" {
  count           = var.ecs_worker_enabled ? 1 : 0
  name            = "${var.project}-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command = true

  network_configuration {
    subnets = [aws_subnet.public[0].id]
    security_groups  = [aws_security_group.ecs_worker.id]
    assign_public_ip = true
  }
}

# ═══════════════════════════════════════════════════════════
# API service
# ═══════════════════════════════════════════════════════════

resource "aws_cloudwatch_log_group" "ecs_api" {
  name              = "/ecs/${var.project}-api"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "api"
    image     = "${aws_ecr_repository.worker.repository_url}:latest"
    essential = true
    command   = ["api"]

    portMappings = [{ containerPort = 8000, hostPort = 8000, protocol = "tcp" }]

    environment = [
      { name = "DATABASE_URL", value = "postgresql+psycopg://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}?sslmode=require" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "AWS_DEFAULT_REGION", value = var.aws_region },
      { name = "S3_ENDPOINT_URL", value = "" },
      { name = "SQS_ENDPOINT_URL", value = "" },
      { name = "S3_BUCKET", value = aws_s3_bucket.docs.id },
      { name = "SQS_QUEUE_NAME", value = aws_sqs_queue.main.name },
      { name = "SQS_QUEUE_URL", value = aws_sqs_queue.main.url },
      { name = "SQS_DLQ_URL", value = aws_sqs_queue.dlq.url },
      { name = "EMBEDDING_PROVIDER", value = "bedrock" },
      { name = "EMBEDDING_MODEL_ID", value = "amazon.titan-embed-text-v2:0" },
      { name = "EMBEDDING_DIMENSIONS", value = "1024" },
      { name = "LLM_MODEL_ID", value = "mistral.mistral-large-3-675b-instruct" },
      { name = "LLM_MAX_TOKENS", value = "1024" },
      { name = "LLM_TEMPERATURE", value = "0.1" },
      { name = "ASK_TOP_K", value = "5" },
      { name = "CHUNK_SIZE_TOKENS", value = "600" },
      { name = "CHUNK_OVERLAP_TOKENS", value = "100" },
      { name = "POSTGRES_USER", value = var.db_username },
      { name = "POSTGRES_PASSWORD", value = var.db_password },
      { name = "POSTGRES_DB", value = var.db_name },
      { name = "POSTGRES_PORT", value = tostring(aws_db_instance.main.port) },
      { name = "COGNITO_USER_POOL_ID", value = aws_cognito_user_pool.main.id },
      { name = "COGNITO_CLIENT_ID", value = aws_cognito_user_pool_client.api.id },
      { name = "COGNITO_REGION", value = var.aws_region },
      { name = "CORS_ALLOWED_ORIGIN", value = var.cors_allowed_origin },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_api.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "api"
      }
    }
  }])
}

resource "aws_ecs_service" "api" {
  name            = "${var.project}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8000
  }

  network_configuration {
    subnets          = [aws_subnet.public[0].id, aws_subnet.public[1].id]
    security_groups  = [aws_security_group.ecs_api.id]
    assign_public_ip = true
  }

  depends_on = [aws_lb_listener.https]
}

# ═══════════════════════════════════════════════════════════
# UI service
# ═══════════════════════════════════════════════════════════

resource "aws_cloudwatch_log_group" "ecs_ui" {
  name              = "/ecs/${var.project}-ui"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "ui" {
  family                   = "${var.project}-ui"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "ui"
    image     = "${aws_ecr_repository.worker.repository_url}:latest"
    essential = true
    command   = ["ui"]

    portMappings = [{ containerPort = 7860, hostPort = 7860, protocol = "tcp" }]

    environment = [
      { name = "DATABASE_URL", value = "postgresql+psycopg://unused:unused@localhost:5432/unused" },
      { name = "POSTGRES_USER", value = "unused" },
      { name = "POSTGRES_PASSWORD", value = "unused" },
      { name = "POSTGRES_DB", value = "unused" },
      { name = "POSTGRES_PORT", value = "5432" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "AWS_DEFAULT_REGION", value = var.aws_region },
      { name = "S3_ENDPOINT_URL", value = "" },
      { name = "SQS_ENDPOINT_URL", value = "" },
      { name = "S3_BUCKET", value = aws_s3_bucket.docs.id },
      { name = "SQS_QUEUE_NAME", value = aws_sqs_queue.main.name },
      { name = "SQS_QUEUE_URL", value = aws_sqs_queue.main.url },
      { name = "API_BASE_URL", value = "https://${var.api_subdomain}.${var.domain_name}" },
      { name = "API_HOST", value = "0.0.0.0" },
      { name = "API_PORT", value = "8000" },
      { name = "UI_HOST", value = "0.0.0.0" },
      { name = "UI_PORT", value = "7860" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_ui.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ui"
      }
    }
  }])
}

resource "aws_ecs_service" "ui" {
  name            = "${var.project}-ui"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ui.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_lb_target_group.ui.arn
    container_name   = "ui"
    container_port   = 7860
  }

  network_configuration {
    subnets          = [aws_subnet.public[0].id, aws_subnet.public[1].id]
    security_groups  = [aws_security_group.ecs_ui.id]
    assign_public_ip = true
  }

  depends_on = [aws_lb_listener.https]
}