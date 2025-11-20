provider "aws" {
  region = var.region
}

provider "kubernetes" {
  config_path = "~/.kube/config"       # Adjust if needed
 
}


terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"   # Latest AWS provider
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"  # Latest Kubernetes provider
    }
  }
}


