#Task 1

We can run Task 1 for deployment of application which has source code on https://github.com/flexsurfer/conduitrn.git repository. For running this script we need to just run the automated shell script as below.

```
bash app_inst.sh
```

This will install docker packages and install docker inside EC2 instance. After that, it will checkout the code and buidl the docker image using dockerfile and create a container which will be hosted on EC2 instance. Below is the URL where we can see the web application with subdomain.

URL: http://web.demo.secucare.in/

# Task 2 

In this task we can use terraform as IAAC for creating EKS cluster. It is using modules to create VPC along with all the networking components, EKS cluster along with worker nodes and karpenter. Karpenter is  an open-source autoscaling solution. EKS cluster is highly available and used helm charts to create cloudwatch agent for monitoring.  Ingress controller is created with the use of helm charts which can be triggered by provider in terraform as helm. Also created metric server using helm charts with helm as provider in terraform.  We can use terraform for single automation tool to deploy all these components.

## Prerequisites for Running Terraform

Before using this Terraform configuration, ensure that you have the following prerequisites in place:

- Terraform installed on your local machine.
- AWS CLI configured with the appropriate AWS access and secret keys.


## Usage to run Terraform code.

To run Terraform follow these steps:


1. Initialize your Terraform environment using `terraform init` to configure the remote state backend.

2. Use Terraform commands like  `terraform plan` to create the plan and undertand what is being created and then run `terraform apply` to create the infrastructure and `terraform destroy` to destroy the infrastructure.