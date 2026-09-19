terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.24"
    }
  }

  provider_meta "aws" {
    user_agent = [
      "github.com/bgauduch/terraform-aws-backup"
    ]
  }
}
