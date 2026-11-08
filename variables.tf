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

variable "ecs_worker_enabled" {
  description = "Create the ECS Fargate worker service. Set false until image is pushed + migrations run."
  type        = bool
  default     = false
}
variable "domain_name" {
  type    = string
  default = "adityalive.tech"
}

variable "ui_subdomain" {
  type    = string
  default = "ai"
}

variable "api_subdomain" {
  type    = string
  default = "api"    # ← NOT "api.ai" — Namify doesn't support nested CNAMEs
}

variable "cors_allowed_origin" {
  type    = string
  default = "https://ai.adityalive.tech"
}
variable "tavily_api_key" {
  description = "Tavily API key for web search"
  type        = string
  sensitive   = true
}
