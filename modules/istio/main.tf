resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.27.1"

  depends_on = [kubernetes_namespace.istio_system]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.27.1"

  set {
    name  = "pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API"
    value = "true"
  }

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.27.1"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  depends_on = [helm_release.istiod]
}
