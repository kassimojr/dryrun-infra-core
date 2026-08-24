terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Valores de bucket/região/tabela vêm de backend.hcl (ver README na raiz):
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    key = "dryrun-infra-core/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "dryrun"
      ManagedBy = "terraform"
      Repo      = "dryrun-infra-core"
    }
  }
}
