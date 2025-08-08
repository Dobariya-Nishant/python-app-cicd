terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket               = "devops-learn-dev"
    key                  = "tf-state-deploy"
    workspace_key_prefix = "tf-state-deploy-env"
    dynamodb_table       = "tf-backend-lock"
    region               = "us-east-1"
    encrypt              = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      Contact     = var.contact
      ManageBy    = "Terraform/setup"
    }
  }
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
}

data "aws_region" "current" {}