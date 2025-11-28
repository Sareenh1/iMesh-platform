# App Gateway
resource "kubectl_manifest" "app_gateway" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  annotations:
    service.beta.kubernetes.io/port_80_no_probe_rule: "true"
    service.beta.kubernetes.io/port_443_no_probe_rule: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  name: app
  namespace: v2
spec:
  gatewayClassName: eg
  listeners:
  - allowedRoutes:
      namespaces:
        from: Same
    hostname: app.${var.domain}
    name: http-ui
    port: 80
    protocol: HTTP
  - name: https
    protocol: HTTPS
    hostname: "app.${var.domain}"
    port: 443
    allowedRoutes:
      namespaces:
        from: Same
    tls:
      mode: Terminate
      certificateRefs:
      - name: dev-imesh-ai-cert
  - allowedRoutes:
      namespaces:
        from: Same
    name: http-graphql
    hostname: services.${var.domain}
    port: 3000
    protocol: HTTP
  - allowedRoutes:
      kinds:
      - kind: TCPRoute
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: v2-deps
    name: tcp
    port: 4222
    protocol: TCP
YAML
}

# Keycloak Gateway
resource "kubectl_manifest" "keycloak_gateway" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  annotations:
    service.beta.kubernetes.io/port_80_no_probe_rule: "true"
    service.beta.kubernetes.io/port_443_no_probe_rule: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
    cert-manager.io/common-name: auth.${var.domain}
  name: keycloak
  namespace: v2-deps
spec:
  gatewayClassName: istio
  listeners:
  - allowedRoutes:
      namespaces:
        from: Same
    hostname: auth.${var.domain}
    name: http
    port: 80
    protocol: HTTP
  - name: https
    protocol: HTTPS
    hostname: auth.${var.domain}
    port: 443
    allowedRoutes:
      namespaces:
        from: Same
    tls:
      mode: Terminate
      certificateRefs:
      - name: auth-dev-imesh-ai-cert
YAML
}

# HTTP Routes
resource "kubectl_manifest" "ui_http_route" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ui
  namespace: v2
spec:
  parentRefs:
  - name: app
    namespace: v2
    sectionName: https
  rules:
  - backendRefs:
    - kind: Service
      name: ui
      port: 80
YAML
}

resource "kubectl_manifest" "http_to_https_redirect" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-to-https-redirect
  namespace: v2
spec:
  hostnames:
  - app.${var.domain}
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: app
    namespace: v2
    sectionName: http-ui
  rules:
  - filters:
    - requestRedirect:
        scheme: https
        statusCode: 301
      type: RequestRedirect
YAML
}

resource "kubectl_manifest" "graphql_backend_http_route" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: graphql-backend
  namespace: v2
spec:
  parentRefs:
  - name: app
    namespace: v2
    port: 3000
  rules:
  - backendRefs:
    - kind: Service
      name: graphql-backend
      port: 80
YAML
}

resource "kubectl_manifest" "keycloak_http_route" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: keycloak
  namespace: v2-deps
spec:
  parentRefs:
  - name: keycloak
    namespace: v2-deps
    sectionName: https
  rules:
  - backendRefs:
    - kind: Service
      name: keycloak
      port: 80
YAML
}

resource "kubectl_manifest" "keycloak_http_to_https_redirect" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-to-https-redirect
  namespace: v2-deps
spec:
  hostnames:
  - auth.${var.domain}
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: keycloak
    namespace: v2-deps
    sectionName: http
  rules:
  - filters:
    - requestRedirect:
        scheme: https
        statusCode: 301
      type: RequestRedirect
YAML
}

resource "kubectl_manifest" "nats_tcp_route" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: nats
  namespace: v2-deps
spec:
  parentRefs:
  - name: app
    namespace: v2
    port: 4222
  rules:
  - backendRefs:
    - name: nats
      namespace: v2-deps
      port: 4222
YAML
}
