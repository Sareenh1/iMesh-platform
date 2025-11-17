# Install Gateway API CRDs using kubectl provider
resource "kubectl_manifest" "gateway_api_crds" {
  for_each = {
    for filename in fileset("${path.module}/crds", "*.yaml") :
    filename => file("${path.module}/crds/${filename}")
  }

  yaml_body = each.value
  wait      = true
}

# Install Envoy Gateway (which includes Gateway API support)
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

  # Wait for CRDs to be installed first
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

# Wait a bit for controllers to be ready
resource "time_sleep" "wait_for_controllers" {
  depends_on = [helm_release.envoy_gateway, helm_release.istiod]
  create_duration = "30s"
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

  depends_on = [time_sleep.wait_for_controllers]
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

  depends_on = [time_sleep.wait_for_controllers]
}

# App Gateway
resource "kubernetes_manifest" "app_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = "app"
      namespace = var.namespaces.v2
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      }
    }
    spec = {
      gatewayClassName = "eg"
      listeners = [
        {
          name     = "http-ui"
          port     = 80
          protocol = "HTTP"
          hostname = "app.${var.domain}"
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        },
        {
          name     = "https"
          port     = 443
          protocol = "HTTPS"
          hostname = "app.${var.domain}"
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = "dev-imesh-ai-cert"
            }]
          }
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        },
        {
          name     = "http-graphql"
          port     = 3000
          protocol = "HTTP"
          hostname = "services.${var.domain}"
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.gateway_class_eg]
}

# Keycloak Gateway
resource "kubernetes_manifest" "keycloak_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = "keycloak"
      namespace = var.namespaces.v2_deps
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      }
    }
    spec = {
      gatewayClassName = "istio"
      listeners = [
        {
          name     = "http"
          port     = 80
          protocol = "HTTP"
          hostname = "auth.${var.domain}"
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        },
        {
          name     = "https"
          port     = 443
          protocol = "HTTPS"
          hostname = "auth.${var.domain}"
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = "auth-dev-imesh-ai-cert"
            }]
          }
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.gateway_class_istio]
}

# HTTP Routes for UI
resource "kubernetes_manifest" "ui_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "ui"
      namespace = var.namespaces.v2
    }
    spec = {
      parentRefs = [{
        name = "app"
        namespace = var.namespaces.v2
      }]
      hostnames = ["app.${var.domain}"]
      rules = [{
        backendRefs = [{
          kind = "Service"
          name = "ui"
          port = 80
        }]
      }]
    }
  }

  depends_on = [kubernetes_manifest.app_gateway]
}

# HTTP Route for GraphQL
resource "kubernetes_manifest" "graphql_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "graphql-backend"
      namespace = var.namespaces.v2
    }
    spec = {
      parentRefs = [{
        name = "app"
        namespace = var.namespaces.v2
      }]
      hostnames = ["services.${var.domain}"]
      rules = [{
        backendRefs = [{
          kind = "Service"
          name = "graphql-backend"
          port = 80
        }]
      }]
    }
  }

  depends_on = [kubernetes_manifest.app_gateway]
}

# HTTP Route for Keycloak
resource "kubernetes_manifest" "keycloak_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "keycloak"
      namespace = var.namespaces.v2_deps
    }
    spec = {
      parentRefs = [{
        name = "keycloak"
        namespace = var.namespaces.v2_deps
      }]
      hostnames = ["auth.${var.domain}"]
      rules = [{
        backendRefs = [{
          kind = "Service"
          name = "keycloak"
          port = 80
        }]
      }]
    }
  }

  depends_on = [kubernetes_manifest.keycloak_gateway]
}
