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


provider "aws" {
  region = var.region
}

provider "kubernetes" {
  config_path = "~/.kube/config"       # Adjust if needed
 
}

# Import all other .tf files implicitly when running terraform
# No need to explicitly include them here, Terraform loads all .tf files

output "eks_cluster_name" {
  value = var.cluster_name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_ca_certificate" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}
