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
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "http"
    type  = "string"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "https"
    type  = "string"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-connection-idle-timeout"
    value = "60"
    type  = "string"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
    #   type      = "string"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = module.acm.acm_certificate_arn
    type  = "string"
  }

  set {
    name  = "controller.containerPort.http-redirect"
    value = 8001
  }
  set {
    name  = "controller.service.targetPorts.https"
    value = "http"
  }
  set {
    name  = "controller.service.targetPorts.http"
    value = "http-redirect"
  }
  set {
    name  = "controller.config.http-snippet"
    value = "server {listen 8001; return 308 https://$host$request_uri;}"
  }
  set {
    name  = "controller.config.proxy-real-ip-cidr"
    value = var.cidr
  }
  set {
    name  = "controller.config.use-forwarded-headers"
    value = "true"
  }

  set {
    name  = "controller.replicaCount"
    value = var.ingress_replica_count
  }

}

## To Get Nginx loadbalancer DNS Name. 
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