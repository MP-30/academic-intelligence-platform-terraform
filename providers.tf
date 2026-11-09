terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # In CI, aws_profile is empty → use default credential chain (OIDC env vars).
  # Locally, aws_profile="terraform-ai" → use that profile from ~/.aws/credentials.
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = {
      Project     = var.project
      ManagedBy   = "terraform"
      Environment = "dev"
    }
  }
}