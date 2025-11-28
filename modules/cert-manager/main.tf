resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  version    = "v1.13.3"

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [kubernetes_namespace.cert_manager]
}

resource "kubectl_manifest" "letsencrypt_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: ${var.email}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
            - name: app
              namespace: v2
              kind: Gateway
            - name: keycloak
              namespace: v2-deps
              kind: Gateway
YAML

  depends_on = [helm_release.cert_manager]
}
