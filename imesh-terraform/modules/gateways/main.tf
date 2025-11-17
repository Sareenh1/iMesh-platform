resource "helm_release" "envoy_gateway" {
  name       = "eg"
  repository = "https://envoyproxy.github.io/gateway-helm"
  chart      = "gateway-helm"
  namespace  = "envoy-gateway-system"
  version    = "1.5.4"

  set {
    name  = "gateway-helm.image.tag"
    value = "v1.5.4"
  }
}

resource "kubectl_manifest" "app_gateway" {
  yaml_body = templatefile("${path.module}/../../manifests/gateway.yaml", {
    v2_namespace = var.namespaces.v2
    v2_deps_namespace = var.namespaces.v2_deps
    domain = var.domain
  })

  depends_on = [helm_release.envoy_gateway]
}

resource "kubectl_manifest" "keycloak_gateway" {
  yaml_body = templatefile("${path.module}/../../manifests/kc-gateway.yaml", {
    namespace = var.namespaces.v2_deps
    domain    = var.domain
  })

  depends_on = [helm_release.envoy_gateway]
}
