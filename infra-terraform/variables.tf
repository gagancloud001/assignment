variable "project" {
  description = "Project Name to be used on all the resources as identifier"
  type        = string
  default     = "demo"
}

variable "env_name" {
  description = "environmen Name to be used on all the resources as identifier"
  type        = string
  default     = "test"
}

variable "region" {
  description = "aws region"
  type        = string
  default     = "eu-central-1"
}

variable "cost_center" {
  type    = string
  default = "484058"
}

############# VPC ##################

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "0.0.0.0/0"
}
variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

############# EKS #################


variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

##### Worker_Groups ################

variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = ""
}

variable "capacity_type" {
  type    = string
  default = "spot"
}

variable "disk_size" {
  default = 50
  type    = number

}

variable "ingress_replica_count" {
  default = 1
  type    = number

}



##################################################################################
# LOCALS
##################################################################################

locals {
  env_name = var.env_name

  common_tags = {
    project     = var.project
    Environment = local.env_name
    cost_center = var.cost_center
    managedby   = "terraform"
  }

  account_id = data.aws_caller_identity.current.account_id

  karpenter_role = [
    {
      rolearn  = try(module.karpenter.role_arn, null)
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
  ]
}


   