terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.21.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.22"
    }

    helm = {
      source = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}