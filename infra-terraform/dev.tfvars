########### General config ###########
env_name    = "dev"
region      = "us-east-2"
project     = "demo"

############# VPC ##################

cidr            = "10.21.0.0/16"
public_subnets  = ["10.21.100.0/22", "10.21.104.0/22"]
private_subnets = ["10.21.0.0/22", "10.21.4.0/22"]


##### Worker_Groups ################
instance_type        = "t3.medium"
asg_desired_capacity = 1
asg_min_size         = 1
asg_max_size         = 2

######Karpenter#####
capacity_type = "spot"
arch_type     = "amd64"

####Ingress Controller#####
ingress_replica_count = 1
