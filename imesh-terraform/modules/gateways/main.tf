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

resource "helm_release" "istio" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"
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

  depends_on = [helm_release.istio]
}

# GatewayClass for Envoy Gateway
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

# GatewayClass for Istio
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

# App Gateway
resource "kubernetes_manifest" "app_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = "app"
      namespace = var.namespaces.v2
      annotations = {
        "service.beta.kubernetes.io/port_80_no_probe_rule" = "true"
        "service.beta.kubernetes.io/port_443_no_probe_rule" = "true"
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
        },
        {
          name     = "tcp"
          port     = 4222
          protocol = "TCP"
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = var.namespaces.v2_deps
                }
              }
            }
            kinds = [{
              kind = "TCPRoute"
            }]
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
        "service.beta.kubernetes.io/port_80_no_probe_rule" = "true"
        "service.beta.kubernetes.io/port_443_no_probe_rule" = "true"
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
        "cert-manager.io/common-name" = "auth.${var.domain}"
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

# UI HTTPRoute
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
        sectionName = "https"
      }]
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

# HTTP to HTTPS Redirect
resource "kubernetes_manifest" "http_to_https_redirect" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "http-to-https-redirect"
      namespace = var.namespaces.v2
    }
    spec = {
      hostnames = ["app.${var.domain}"]
      parentRefs = [{
        group = "gateway.networking.k8s.io"
        kind = "Gateway"
        name = "app"
        namespace = var.namespaces.v2
        sectionName = "http-ui"
      }]
      rules = [{
        filters = [{
          type = "RequestRedirect"
          requestRedirect = {
            scheme = "https"
            statusCode = 301
          }
        }]
      }]
    }
  }

  depends_on = [kubernetes_manifest.app_gateway]
}

# GraphQL Backend HTTPRoute
resource "kubernetes_manifest" "graphql_backend_route" {
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
        port = 3000
      }]
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

# NATS TCPRoute
resource "kubernetes_manifest" "nats_tcp_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1alpha2"
    kind       = "TCPRoute"
    metadata = {
      name = "nats"
      namespace = var.namespaces.v2_deps
    }
    spec = {
      parentRefs = [{
        name = "app"
        namespace = var.namespaces.v2
        port = 4222
      }]
      rules = [{
        backendRefs = [{
          name = "nats"
          namespace = var.namespaces.v2_deps
          port = 4222
        }]
      }]
    }
  }

  depends_on = [kubernetes_manifest.app_gateway]
}

# Keycloak HTTPRoute
resource "kubernetes_manifest" "keycloak_http_route" {
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
        sectionName = "https"
      }]
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

# Keycloak HTTP to HTTPS Redirect
resource "kubernetes_manifest" "keycloak_http_to_https_redirect" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "http-to-https-redirect"
      namespace = var.namespaces.v2_deps
    }
    spec = {
      hostnames = ["auth.${var.domain}"]
      parentRefs = [{
        group = "gateway.networking.k8s.io"
        kind = "Gateway"
        name = "keycloak"
        namespace = var.namespaces.v2_deps
        sectionName = "http"
      }]
      rules = [{
        filters = [{
          type = "RequestRedirect"
          requestRedirect = {
            scheme = "https"
            statusCode = 301
          }
        }]
      }]
    }
  }

  depends_on = [kubernetes_manifest.keycloak_gateway]
}
