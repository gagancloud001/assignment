module "vpc" {
  source = "./modules/vpc"

  name = "${var.project}-${local.env_name}-vpc"
  cidr = var.cidr

  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  single_nat_gateway = true

  # Add those tags for EKS

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