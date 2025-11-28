resource "kubernetes_namespace" "v2" {
  metadata {
    name = "v2"
  }
}

resource "kubernetes_namespace" "v2_agent" {
  metadata {
    name = "v2-agent"
  }
}

resource "kubernetes_namespace" "v2_deps" {
  metadata {
    name = "v2-deps"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
  }
}

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}
