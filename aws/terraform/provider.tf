# --- AWS Provider Configuration ---
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  profile    = var.aws_profile
  access_key = var.access_key
  secret_key = var.secret_key

  default_tags {
    tags = var.default_tags
  }
}
