terraform {
  backend "s3" {
    bucket       = "academic-rag-tfstate-1794051971"
    key          = "academic-rag/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}