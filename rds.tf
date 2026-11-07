resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_parameter_group" "pg18_vector_opts" {
  name   = "${var.project}-pg18-vector-opts"
  family = "postgres18"

  parameter {
    name  = "maintenance_work_mem"
    value = "262144"
  }
  parameter {
    name  = "max_parallel_maintenance_workers"
    value = "2"
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

  publicly_accessible     = false          # ← CHANGED: no public IP
  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  performance_insights_enabled = false
}