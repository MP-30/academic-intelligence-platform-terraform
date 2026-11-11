# Academic Intelligence Platform — Infrastructure

[![Terraform Plan](https://github.com/MP-30/academic-intelligence-platform-terraform/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/MP-30/academic-intelligence-platform-terraform/actions/workflows/terraform-plan.yml)
[![Terraform 1.10+](https://img.shields.io/badge/terraform-1.10%2B-623CE4.svg)](https://www.terraform.io/)
[![AWS us-east-1](https://img.shields.io/badge/AWS-us--east--1-orange.svg)](https://aws.amazon.com/)

Terraform code for the AWS backend of the [Academic Intelligence Platform](https://github.com/MP-30/Academic-Intelligence-Platform).

**Live:** [https://ai.adityalive.tech](https://ai.adityalive.tech)

---

## What This Provisions

| Component | Details |
|---|---|
| **VPC** | Custom `10.0.0.0/16` · 2 public + 2 private subnets across `us-east-1a`/`1b` · Internet Gateway · S3 Gateway endpoint · **no NAT gateway** (cost optimization) |
| **RDS PostgreSQL 18** | `db.t3.micro` · **private subnet** · SG-to-SG access from API/worker SGs · SSL enforced · pgvector-optimized parameter group (`maintenance_work_mem=256MB` for `t3.micro`) |
| **S3 bucket** | PDF storage · versioned · public access blocked · accessed via gateway endpoint (free, traffic stays in AWS network) |
| **SQS** | `ingestion-jobs` main queue + DLQ · visibility 300s · `maxReceiveCount=5` auto-redrive · `ReceiveMessageWaitTimeSeconds=20` long polling |
| **ECR** | `academic-rag-worker` repository · 5-image lifecycle policy |
| **ECS Fargate** | 3 services: **api** (3 containers: api + doc-mcp + web-mcp, 512 CPU / 1024 MB), **worker** (1 container, 256/512), **ui** (1 container, 256/512) |
| **ALB + ACM** | HTTPS listener (443) · ACM cert with DNS validation for `ai.adityalive.tech` + `api.adityalive.tech` · host-header routing · HTTP → HTTPS redirect |
| **Cognito** | User pool + client · email verification · `USER_PASSWORD_AUTH` flow · 60-min id_token validity |
| **IAM** | 4 roles: `ecs-execution` (pull image, push logs), `ecs-task` (Bedrock, S3, SQS, Cognito access), `GitHubActionsDeployRole` (ECR + ECS), `GitHubActionsTerraformPlanRole` (ReadOnly + state bucket) |
| **CloudWatch** | Log groups for api, worker, ui · 7-day retention |

**Total resources:** ~35 (VPC, subnets, SGs, RDS, S3, SQS, ECR, ECS tasks + services, ALB, ACM, Cognito, IAM roles + policies, log groups, Route53 records).

---

## Prerequisites

1. **AWS account** with billing enabled
2. **AWS CLI** configured with an admin profile (default: `terraform-ai`)
3. **Terraform ≥ 1.10** — [install](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
4. **Domain** registered — currently `adityalive.tech` (DNS hosted at Namify, but works with any registrar)
5. **S3 state bucket** — created once manually (Terraform can't create its own backend)

### Create the S3 state bucket (one-time, ~30 sec)

```bash
# Replace `<unique-suffix>` with something like a timestamp
BUCKET="academic-rag-tfstate-$(date +%s)"
echo "Bucket name: $BUCKET"

aws s3 mb "s3://$BUCKET" --profile terraform-ai --region us-east-1
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled \
  --profile terraform-ai --region us-east-1
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile terraform-ai --region us-east-1

# Update backend.tf with this bucket name
sed -i "s|academic-rag-tfstate-1794051971|$BUCKET|" backend.tf