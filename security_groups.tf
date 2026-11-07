# RDS: accepts ONLY from ECS worker SG + your laptop IP

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Postgres access for ${var.project}"
  vpc_id      = aws_vpc.main.id

  # No inline ingress — all ingress rules are standalone below.
  # Mixing inline + standalone causes Terraform's authoritative inline
  # management to revoke standalone rules on every SG update. This is
  # the root cause of the "worker SG rule disappeared" bug.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_laptop" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = local.my_ip
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  description       = "Postgres from my laptop"
}

# Allow ECS worker SG → RDS (SG-to-SG, no public internet)
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs_worker.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Postgres from ECS worker"
}


# ECS worker: outbound only, no inbound

resource "aws_security_group" "ecs_worker" {
  name        = "${var.project}-ecs-worker-sg"
  description = "ECS worker - outbound only"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "All outbound (Bedrock, S3, SQS, RDS via VPC)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── ALB: 80/443 from internet ──
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "ALB HTTPS ingress"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── API: 8000 from ALB only ──
resource "aws_security_group" "ecs_api" {
  name        = "${var.project}-ecs-api-sg"
  description = "API inbound from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── UI: 7860 from ALB only ──
resource "aws_security_group" "ecs_ui" {
  name        = "${var.project}-ecs-ui-sg"
  description = "UI inbound from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 7860
    to_port         = 7860
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── RDS: allow API (for /search and /ask) ──
resource "aws_vpc_security_group_ingress_rule" "rds_from_api" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs_api.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Postgres from API"
}