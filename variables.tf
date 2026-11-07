variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile for Terraform"
  type        = string
  default     = "terraform-ai"
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "academic-rag"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "academic"
}

variable "db_password" {
  description = "RDS master password (min 8 chars)"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "academic_db"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_publicly_accessible" {
  description = "Allow public RDS access (for local dev only)"
  type        = bool
  default     = true
}

variable "bedrock_dev_user" {
  description = "IAM user name that runs the application (Bedrock profile)"
  type        = string
  default     = "bedrock-dev"
}