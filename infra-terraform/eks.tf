### For EKS

data "aws_eks_cluster" "cluster" {
  depends_on = [module.eks.cluster_endpoint]
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks.cluster_endpoint]
  name       = module.eks.cluster_name

}

# For karpenter provisioner, To get sercurity group name.

data "aws_security_group" "worker_security_group" {
  depends_on = [module.eks.cluster_endpoint]
  id         = module.eks.node_security_group_id
}


module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.project}-${local.env_name}"
  cluster_version = "1.27"

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  manage_aws_auth_configmap = true
  aws_auth_roles            = concat(try(var.map_roles, []), try(local.karpenter_role, []))
  /* aws_auth_users            = var.map_users */

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

  ## EKS Managed Node Group(s)
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
      iam_role_attach_cni_policy = true
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