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