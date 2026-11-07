# Academic Intelligence Platform — Infrastructure

Terraform for the AWS backend of the Academic RAG project.

## What this creates

- **RDS Postgres 16.4** (`db.t3.micro`, free tier) with pgvector support
- **S3 bucket** for PDF storage
- **SQS queue + DLQ** for async ingestion
- **IAM policy** attached to `bedrock-dev` user granting S3 + SQS access

## Quick start

\`\`\`bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set db_password

terraform init
terraform plan
terraform apply
\`\`\`

## After apply

\`\`\`bash
terraform output -raw rds_host
terraform output -raw database_url_asyncpg
terraform output -raw sqs_queue_url
\`\`\`

## Teardown

\`\`\`bash
terraform destroy
\`\`\`

State stored in `s3://academic-rag-tfstate-1794051971/academic-rag/terraform.tfstate`