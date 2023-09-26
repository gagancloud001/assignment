################################################################################
# Karpenter
################################################################################

module "karpenter" {
  source                   = "./modules/karpenter"
  depends_on               = [module.eks.cluster_endpoint]
  cluster_name             = module.eks.cluster_name
  irsa_oidc_provider_arn   = module.eks.oidc_provider_arn
  irsa_use_name_prefix     = false
  iam_role_use_name_prefix = false
  iam_role_description     = "Use for eks node auto scling using Karpenter"

  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]

  tags = local.common_tags
}

## Install karpenter Operator

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

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
  set {
    name  = "replicas"
    value = "1"
  }
  set {
    name  = "controller.logLevel"
    value = "error"
  }

}



## Karpenter Provisioner

resource "kubectl_manifest" "karpenter_provisioner" {
  depends_on = [helm_release.karpenter]
  yaml_body  = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      blockDeviceMappings:
      - deviceName: /dev/xvda
        ebs:
          deleteOnTermination: true
          volumeSize: 50Gi
          volumeType: gp3
      consolidation:
        enabled: true
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["${var.capacity_type}"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: karpenter.k8s.aws/instance-family
          operator: NotIn
          values: [c1, cc1, cc2, cg1, cg2, cr1, cs1, g1, g2, hi1, hs1, m1, m2, m3, t1] 
      limits:
        resources:
          cpu: 50
      provider:
        securityGroupSelector:
          Name: "${data.aws_security_group.worker_security_group.tags["Name"]}"
        subnetSelector:
          karpenter.sh/subnet: "private"
        tags:
          karpenter.sh/discovery: "${module.eks.cluster_name}"
          env_name: "${var.env_name}"
          project: "${var.project}"
          managedby: "terraform"
          capacity-type: "${var.capacity_type}"
  YAML
}
