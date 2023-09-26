terraform {

  required_version = ">= 0.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.22.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

## Terrafrom state Backend config
/* terraform {
  backend "s3" {
    bucket         = "terraform-state-artifacts"
    region         = "us-east-2"
    key            = "demo/dev/dev.tfstate"
    dynamodb_table = "terraform-state-artifact-locks"
  }
} */

## Default Provider
provider "aws" {
  region     = var.region
  access_key = "XXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXX"
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm Provider

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# # Kubectl Provider

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
