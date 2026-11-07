data "aws_caller_identity" "current" {}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  my_ip      = "${chomp(data.http.my_ip.response_body)}/32"

  common_tags = {
    Project = var.project
  }
}