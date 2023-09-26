resource "helm_release" "metrics-server" {
  depends_on = [module.eks.cluster_endpoint]
  namespace  = "kube-system"

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
}