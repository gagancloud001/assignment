# Terraform Configuration

This README provides an overview of the Terraform configuration used for managing infrastructure and resources in your environment. Terraform is an infrastructure-as-code (IaC) tool that allows you to define and provision infrastructure resources using code.

## Prerequisites

Before using this Terraform configuration, ensure that you have the following prerequisites in place:

- Terraform installed on your local machine.
- AWS CLI configured with the appropriate AWS access and secret keys.

## Terraform Version and Providers

```hcl
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
```

This Terraform configuration defines the required Terraform version and specifies the providers used in your infrastructure code. It includes providers for AWS, Kubernetes, Helm, kubectl, TLS, and random resource generation.

## Provider Configuration

The provider configurations for AWS, Kubernetes, Helm, and kubectl are specified below:

```hcl
provider "aws" {
  region     = var.region
  access_key = "XXXXXXXXXXXXX"  # Replace with your AWS access key
  secret_key = "XXXXXXXXXXXXXXXXXX"  # Replace with your AWS secret key
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
```

- The AWS provider configuration includes the AWS region and your AWS access and secret keys. Make sure to replace the placeholders with your actual AWS credentials.

- The Kubernetes provider configuration is used to interact with your EKS cluster.

- The Helm provider configuration allows you to use Helm to manage Kubernetes applications and resources.

- The kubectl provider configuration enables you to run kubectl commands against your EKS cluster.

# Terraform State Backend Configuration (Optional)

This README section provides information on how to configure a remote Terraform state backend for storing your Terraform state files. A remote state backend is recommended for collaborative projects and to ensure safe state storage and locking.

## Prerequisites

Before configuring a remote Terraform state backend, make sure you have the following prerequisites in place:

- Terraform installed on your local machine.
- Appropriate AWS CLI access and secret keys configured.
- An S3 bucket and DynamoDB table set up for remote state storage and locking.

## Terraform State Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-artifacts"
    region         = "us-east-2"
    key            = "demo/dev/dev.tfstate"
    dynamodb_table = "terraform-state-artifact-locks"
  }
}
```

In this configuration:

- The `terraform` block specifies the use of a remote state backend of type "s3."

- The `bucket` attribute should be set to the name of the S3 bucket where Terraform state files will be stored. You should replace `"terraform-state-artifacts"` with the name of your S3 bucket.

- The `region` attribute specifies the AWS region in which the S3 bucket and DynamoDB table are located. Modify it according to your region.

- The `key` attribute specifies the path within the S3 bucket where Terraform state files will be stored. You can customize the path and filename as needed.

- The `dynamodb_table` attribute specifies the name of the DynamoDB table used for state locking. Replace `"terraform-state-artifact-locks"` with your DynamoDB table name.

## Usage

To use a remote state backend, follow these steps:

1. Uncomment the Terraform state backend configuration in your `main.tf` or configuration files.

2. Initialize your Terraform environment using `terraform init` to configure the remote state backend.

3. Use Terraform commands like `terraform apply` and `terraform destroy` as usual to manage your infrastructure.

With a remote state backend, you can collaborate with others on the same infrastructure code, ensure state consistency, and have a secure and centralized location for storing Terraform state files.




# Module: VPC

This Terraform module creates an Amazon Virtual Private Cloud (VPC) with associated subnets and networking resources.

## Prerequisites

Before using this module, make sure you have the following prerequisites in place:

- Terraform installed on your local machine.
- AWS CLI configured with appropriate credentials.

## Usage

To use this module, include it in your Terraform configuration. Here's an example of how to use it:

```hcl
module "vpc" {
  source = "./modules/vpc"

  # VPC Configuration
  name = "${var.project}-${local.env_name}-vpc"
  cidr = var.cidr

  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  single_nat_gateway = true

  # Tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                        = 1
    "kubernetes.io/cluster/${var.project}-${local.env_name}" = "owned"
    "karpenter.sh/discovery"                                 = "${var.project}-${local.env_name}"
    "karpenter.sh/subnet"                                    = "private"
  }

  tags = merge(
    local.common_tags,
    {
      "kubernetes.io/cluster/${var.project}-${local.env_name}" = "shared"
    },
  )
}
```

In this example:

- The module is sourced from a local directory `./modules/vpc`.
- The VPC is configured with a name, CIDR block, availability zones, and subnet details.
- Tags are added to the VPC, public subnets, and private subnets for integration with Kubernetes and other tools.

Make sure to replace the placeholders like `${var.project}`, `${local.env_name}`, `var.cidr`, `var.private_subnets`, `var.public_subnets`, and `local.common_tags` with your actual project-specific values and configurations.

## Inputs

This module accepts various inputs to customize the VPC and subnet configuration. Refer to the module's documentation for a detailed list of input variables and their descriptions.

## Outputs

The module provides outputs that can be useful for referencing resources created by the module in other parts of your Terraform configuration.

# EKS Cluster and Karpenter Provisioner Configuration

This README provides an example of configuring an Amazon Elastic Kubernetes Service (EKS) cluster and setting up the Karpenter provisioner using Terraform modules.

## Prerequisites

Before using these configurations, ensure you have the following prerequisites:

- Terraform installed on your local machine.
- AWS CLI configured with appropriate credentials.
- Familiarity with Terraform and AWS concepts.

## EKS Cluster Configuration

The following Terraform configuration sets up an EKS cluster:

```hcl
module "eks" {
  source = "./modules/eks"

  # Cluster Configuration
  cluster_name    = "${var.project}-${local.env_name}"
  cluster_version = "1.27"

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  manage_aws_auth_configmap = true
  aws_auth_roles            = concat(try(var.map_roles, []), try(local.karpenter_role, []))

  # Add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }
  }

  # Managed Node Group Configuration
  eks_managed_node_group_defaults = {
    default_node_group = {
      iam_role_attach_cni_policy = true
      use_custom_launch_template = false
      disk_size                  = var.disk_size
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  eks_managed_node_groups = {
    eksMG = {
      description                = "EKS managed node group launch template"
      subnet_ids                 = module.vpc.private_subnets
      capacity_type              = "ON_DEMAND"
      instance_types             = [var.instance_type]
      asg_desired_capacity       = var.asg_desired_capacity
      asg_min_size               = var.asg_min_size
      asg_max_size               = var.asg_max_size
      disk_size                  = var.disk_size
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      tags = merge(
        local.common_tags,
        {
          "kubernetes.io/cluster/${var.project}-${local.env_name}" = "shared"
          "karpenter.sh/discovery"                                 = "${var.project}-${local.env_name}"
        },
      )
    }
  }

  tags = merge(
    local.common_tags,
    {
      "kubernetes.io/cluster/${var.project}-${local.env_name}" = "shared"
      "karpenter.sh/discovery"                                 = "${var.project}-${local.env_name}"
    },
  )
}
```

In this configuration:

- The EKS cluster is created with specified settings including name, version, VPC, and subnets.
- Cluster add-ons like CoreDNS, kube-proxy, AWS EBS CSI Driver, and VPC CNI are configured.
- Managed node groups are defined with desired capacity, instance types, and IAM policies.
- Tags are added for resource organization and integration with Kubernetes and Karpenter.

Please ensure you customize the variables and values to match your specific project requirements.

## Data Sources

The following data sources are used in the configuration:

- `data "aws_eks_cluster"`: Retrieves information about the EKS cluster.
- `data "aws_eks_cluster_auth"`: Retrieves authentication information for the EKS cluster.
- `data "aws_security_group"`: Retrieves information about the security group used for worker nodes.

# Karpenter Configuration

This README provides an overview of configuring Karpenter, a node auto-scaling provisioner, using Terraform modules for your Amazon Elastic Kubernetes Service (EKS) cluster.

## Why Use Karpenter?

Karpenter is a Kubernetes cluster autoscaler that optimizes node usage by provisioning nodes only when necessary. It helps you manage your Kubernetes cluster more efficiently and save costs by scaling nodes up or down based on demand.

## Benefits of Using Karpenter

- **Cost Efficiency**: Karpenter ensures that you have the right number of nodes running at any given time, minimizing overprovisioning and reducing costs.

- **Improved Resource Utilization**: Nodes are scaled down during periods of low demand, freeing up resources for other workloads.

- **Ease of Use**: Karpenter seamlessly integrates with your EKS cluster and is easy to configure using Terraform.

- **Automated Scaling**: Karpenter automatically manages node scaling, so you don't have to worry about manual adjustments.

## Configuration Example

To use Karpenter with your EKS cluster, follow these configuration steps:

1. Configure the Karpenter module:

```hcl
module "karpenter" {
  source                   = "./modules/karpenter"
  depends_on               = [module.eks.cluster_endpoint]
  cluster_name             = module.eks.cluster_name
  irsa_oidc_provider_arn   = module.eks.oidc_provider_arn
  irsa_use_name_prefix     = false
  iam_role_use_name_prefix = false
  iam_role_description     = "Use for eks node auto scaling using Karpenter"

  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  iam_role_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]

  tags = local.common_tags
}
```

2. Install the Karpenter Operator using Helm:

```hcl
resource "helm_release" "karpenter" {
  depends_on       = [module.eks.cluster_endpoint]
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.28.0"

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  # ... (other settings)

  set {
    name  = "controller.logLevel"
    value = "error"
  }
}
```

3. Configure the Karpenter Provisioner:

```hcl
resource "kubectl_manifest" "karpenter_provisioner" {
  depends_on = [helm_release.karpenter]
  yaml_body  = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      # ... (provisioner configuration)
  YAML
}
```

In this example, we first configure the Karpenter module with required IAM roles and policies. Then, we install the Karpenter Operator using Helm, and finally, we define the Karpenter provisioner configuration.

Feel free to adjust the configuration to match your specific requirements and EKS cluster setup.

# Metrics Server Installation

This README provides instructions on how to install Metrics Server in your Amazon Elastic Kubernetes Service (EKS) cluster using Terraform and Helm.

## Prerequisites

Before proceeding with the installation, make sure you have the following prerequisites in place:

- Terraform installed on your local machine.
- AWS CLI configured with appropriate credentials.
- Helm installed in your Kubernetes cluster.

## Metrics Server Installation

To install Metrics Server in your EKS cluster, you can use the following Terraform configuration:

```hcl
resource "helm_release" "metrics-server" {
  depends_on = [module.eks.cluster_endpoint]
  namespace  = "kube-system"

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
}
```

In this configuration:

- The `helm_release` resource installs the Metrics Server Helm chart.
- It is deployed in the `kube-system` namespace, which is the recommended namespace for cluster-level components.
- The Helm chart repository is specified as `https://kubernetes-sigs.github.io/metrics-server`, and the chart name is `metrics-server`.

Make sure to apply this Terraform configuration to your EKS cluster to install Metrics Server.

## What is Metrics Server?

Metrics Server is a scalable and efficient metrics collection and aggregation system for Kubernetes. It collects resource usage metrics, such as CPU and memory usage, from nodes and pods in your cluster. These metrics are essential for monitoring and auto-scaling purposes.

## Usage

After installing Metrics Server, you can use it to:

- Enable Horizontal Pod Autoscaling (HPA): Metrics Server provides the necessary metrics for HPA, allowing your applications to automatically scale based on resource utilization.

- Monitor Cluster Resource Usage: You can use Metrics Server to monitor resource usage in your EKS cluster, helping you identify and address performance bottlenecks.

- Troubleshoot Performance Issues: Metrics Server metrics can be valuable for diagnosing performance issues within your Kubernetes workloads.

# PostgreSQL High-Availability (HA) Deployment

This README provides instructions on how to deploy a High-Availability (HA) instance of PostgreSQL in your Amazon Elastic Kubernetes Service (EKS) cluster using Terraform and Helm.

## Prerequisites

Before proceeding with the deployment, make sure you have the following prerequisites in place:

- Terraform installed on your local machine.
- AWS CLI configured with appropriate credentials.
- Helm installed in your Kubernetes cluster.

## PostgreSQL HA Deployment

To deploy PostgreSQL HA in your EKS cluster, you can use the following Terraform configuration:

```hcl
resource "helm_release" "psql" {
  depends_on       = [module.eks.cluster_endpoint]
  namespace        = "psql-${local.env_name}"
  create_namespace = true
  name             = "postgresql"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql-ha"
  version          = "15.4.0"

  set {
    name  = "global.postgresql.postgresqlUsername"
    value = base64decode("cG9zdGdyZXM=")
  }

  set {
    name  = "global.postgresql.postgresqlPassword"
    value = base64decode("cG9zdGdyZXM=")
  }

  set {
    name  = "global.postgresql.postgresqlDatabase"
    value = base64decode("cG9zdGdyZXM=")
  }

  set {
    name  = "global.postgresql.replicaCount"
    value = "1"
  }
}
```

In this configuration:

- The `helm_release` resource installs the PostgreSQL HA Helm chart.
- It is deployed in a specific namespace named `psql-${local.env_name}`. You can customize the namespace by changing `${local.env_name}` as needed.
- The Helm chart is retrieved from the Bitnami chart repository at `https://charts.bitnami.com/bitnami`, and the chart name is `postgresql-ha`.
- PostgreSQL credentials and database name are specified using base64-encoded values for security.
- The `global.postgresql.replicaCount` is set to `1`, indicating a single replica. You can adjust this value for higher availability.

Make sure to apply this Terraform configuration to your EKS cluster to deploy PostgreSQL HA.

## What is PostgreSQL HA?

PostgreSQL High-Availability (HA) ensures that your PostgreSQL database remains available and operational even in the face of hardware failures, software crashes, or planned maintenance. HA deployments typically involve multiple PostgreSQL nodes and use replication and failover mechanisms to provide continuous service.

## Usage

After deploying PostgreSQL HA, you can:

- Access the PostgreSQL database using the provided credentials.
- Configure your applications to connect to the PostgreSQL HA cluster for high availability and data redundancy.
- Monitor and manage your PostgreSQL HA deployment as needed.

# Amazon Elastic Container Registry (ECR) Configuration

This README provides instructions on how to configure Amazon Elastic Container Registry (ECR) using Terraform modules. ECR is a fully-managed Docker container registry that makes it easy for developers to store, manage, and deploy Docker container images.

## Prerequisites

Before proceeding with the configuration, make sure you have the following prerequisites in place:

- Terraform installed on your local machine.
- AWS CLI configured with appropriate credentials.

## ECR Configuration

To configure ECR using Terraform, you can use the following Terraform configuration:

```hcl
locals {
  ecr_repositories = [
    "app-${local.env_name}",
  ]
}

module "ecr" {
  source          = "./modules/ecr"
  for_each        = toset(local.ecr_repositories)
  repository_name = each.key
  tags            = local.common_tags
}
```

In this configuration:

- The `locals` block defines a list of ECR repositories. You can customize the list by adding or modifying repository names as needed. Each repository name includes `${local.env_name}`, which can be used to differentiate environments.

- The `module "ecr"` block uses a custom ECR module (`./modules/ecr`) to create ECR repositories for each repository name specified in the `ecr_repositories` list.

- The `for_each` argument iterates through the repository names, creating separate ECR repositories for each one.

- Tags are added to the ECR repositories for resource organization and management.

Make sure to apply this Terraform configuration to create the specified ECR repositories.

## What is Amazon ECR?

Amazon Elastic Container Registry (ECR) is a fully-managed Docker container registry service that makes it easy to store, manage, and deploy Docker container images. It integrates seamlessly with Amazon ECS, Amazon EKS, and other AWS services, allowing you to easily deploy containerized applications in AWS.

## Usage

After configuring ECR, you can:

- Push Docker container images to the created ECR repositories.
- Use the ECR repositories as image sources for your Amazon ECS or Amazon EKS clusters.
- Implement container image versioning and access control policies as needed.

ECR is a fundamental component for managing container images in AWS, and it provides a secure and scalable solution for container image storage.

# CloudWatch Agent Installation

This README provides instructions on how to install the CloudWatch Agent Helm chart in your Amazon Elastic Kubernetes Service (EKS) cluster using Terraform and Helm.

## Prerequisites

Before proceeding with the installation, ensure you have the following prerequisites:

- Terraform installed on your local machine.
- AWS CLI configured with appropriate credentials.
- Helm installed in your Kubernetes cluster.

## CloudWatch Agent Installation

To install the CloudWatch Agent in your EKS cluster, you can use the following Terraform configuration:

```hcl
resource "helm_release" "observations_cloudwatch_agent" {
  name             = "cloudwatch-agent"
  chart            = "cloudwatch-agent"
  repository       = "./helm_charts"
  create_namespace = true
  namespace        = "cloudwatch-${local.env_name}"
  depends_on = [
    module.eks
  ]
  values = [
    templatefile("./helm_charts/cloudwatch-agent/values.yaml",
      {
        deployment_stage = local.env_name
        cluster_name     = "${var.project}-${local.env_name}"
      }
    )
  ]
}
```

In this configuration:

- The `helm_release` resource installs the CloudWatch Agent Helm chart.
- The chart is retrieved from the local repository specified by `./helm_charts`. You should replace this with the actual location of your Helm chart repository.
- The Helm release is created in the `cloudwatch-${local.env_name}` namespace, which can be customized by changing `${local.env_name}`.
- The Helm release depends on the successful creation of the EKS cluster, specified using `depends_on`.

Make sure to apply this Terraform configuration to your EKS cluster to install the CloudWatch Agent.

## What is the CloudWatch Agent?

The CloudWatch Agent is a unified agent for collecting system and application metrics from your EC2 instances and on-premises servers. It allows you to collect and monitor logs and metrics from a variety of sources, including the operating system, AWS services, and custom applications.

## Usage

After installing the CloudWatch Agent, you can:

- Configure it to collect and send logs and metrics to Amazon CloudWatch for monitoring and analysis.
- Customize the agent's behavior and metrics collection settings using Helm values.
- Utilize CloudWatch Logs and Metrics for monitoring and troubleshooting your applications and infrastructure.

The CloudWatch Agent is a powerful tool for gaining insights into your AWS resources and applications, helping you maintain optimal performance and availability.

# NGINX Ingress Controller

This README provides instructions on how to deploy the NGINX Ingress Controller in your Kubernetes cluster using Terraform and Helm. The NGINX Ingress Controller is a popular solution for managing ingress traffic to your applications.

## Prerequisites

Before proceeding, ensure you have the following prerequisites:

- Terraform installed on your local machine.
- AWS CLI configured with appropriate credentials.
- Helm installed in your Kubernetes cluster.

## NGINX Ingress Controller Installation

To install the NGINX Ingress Controller, you can use the following Terraform configuration:

```hcl
resource "helm_release" "nginx_release" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  version          = "4.1.4"
  create_namespace = true

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
    type  = "string"
  }

  # ... (other Helm values for customization)
}
```

In this configuration:

- The `helm_release` resource deploys the NGINX Ingress Controller using Helm.

- The NGINX Ingress Controller chart is fetched from the official NGINX Helm repository.

- Helm values are set to customize the controller's behavior. For example, it's configured to use an AWS Network Load Balancer (NLB) for AWS deployments.

Make sure to customize the Helm values based on your requirements.

## Obtain NGINX Load Balancer DNS Name

After deploying the NGINX Ingress Controller, you can obtain the DNS name of the load balancer it creates using Terraform data sources and resources:

```hcl
data "kubernetes_service" "service" {
  depends_on = [helm_release.nginx_release]
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

resource "aws_route53_record" "web" {
  depends_on = [data.kubernetes_service.service]

  for_each = { for domain in module.acm.distinct_domain_names : domain => domain } # Convert list to map
  zone_id  = data.aws_route53_zone.get_zone_id.zone_id
  name     = each.value
  type     = "CNAME"
  ttl      = "5"
  records  = try([data.kubernetes_service.service.status[0].load_balancer[0].ingress[0].hostname], [])
}
```

This Terraform code:

- Retrieves information about the NGINX Ingress Controller service running in the "ingress-nginx" namespace.

- Uses AWS Route 53 to create CNAME records pointing to the load balancer's DNS name for your specified domains.

The NGINX Ingress Controller is now set up to route traffic to your applications based on ingress rules.

## ACM Certificate (Optional)

The module also includes configuration for managing ACM certificates and Route 53 records if you need to associate SSL certificates with your domains.

## Usage

After configuring and applying this Terraform configuration, you'll have the NGINX Ingress Controller deployed in your Kubernetes cluster, ready to route incoming traffic to your applications.
