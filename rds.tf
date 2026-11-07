# ─────────────────────────────────────────────────────────────
# RDS Postgres 18 with pgvector-optimized parameter group
# ─────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnets"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Postgres access for ${var.project}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Postgres from my IP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_parameter_group" "pg18_vector_opts" {
  name   = "${var.project}-pg18-vector-opts"
  family = "postgres18"

  parameter {
    name  = "maintenance_work_mem"
    value = "1048576"   # 1 GB — speeds up HNSW index builds
  }

  parameter {
    name  = "max_parallel_maintenance_workers"
    value = "4"
  }
}

resource "aws_db_instance" "main" {
  identifier             = "${var.project}-db"
  engine                 = "postgres"
  engine_version         = "18.1"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.pg18_vector_opts.name

  publicly_accessible     = var.rds_publicly_accessible
  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  performance_insights_enabled = false
}