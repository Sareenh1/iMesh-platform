# Install Gateway API CRDs first
resource "kubectl_manifest" "gateway_api_crds" {
  for_each = fileset("${path.module}/crds", "*.yaml")
  
  yaml_body = file("${path.module}/crds/${each.value}")
  
  # Wait for the CRDs to be established
  wait = true
}

# Install Envoy Gateway
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

  depends_on = [kubectl_manifest.gateway_api_crds]
}

# Install Istio
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"

  depends_on = [kubectl_manifest.gateway_api_crds]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"

  set {
    name  = "pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API"
    value = "true"
  }

  depends_on = [helm_release.istio_base]
}

# Now create GatewayClass resources
resource "kubernetes_manifest" "gateway_class_eg" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "eg"
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
    }
  }

  depends_on = [helm_release.envoy_gateway]
}

resource "kubernetes_manifest" "gateway_class_istio" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "istio"
    }
    spec = {
      controllerName = "istio.io/gateway-controller"
    }
  }

  depends_on = [helm_release.istiod]
}

# Rest of your gateway resources remain the same...
# [Keep all the Gateway, HTTPRoute, TCPRoute resources from previous version]
