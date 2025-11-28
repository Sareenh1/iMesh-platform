resource "kubernetes_namespace" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
  }
}

resource "helm_release" "envoy_gateway" {
  name       = "eg"
  repository = "oci://docker.io/envoyproxy/gateway-helm"
  chart      = "gateway-helm"
  version    = "v1.5.4"
  namespace  = kubernetes_namespace.envoy_gateway_system.metadata[0].name

  set {
    name  = "config.gateway.controllerName"
    value = "gateway.envoyproxy.io/gatewayclass-controller"
  }

  depends_on = [kubernetes_namespace.envoy_gateway_system]
}

resource "kubectl_manifest" "envoy_gateway_class" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
YAML

  depends_on = [helm_release.envoy_gateway]
}
