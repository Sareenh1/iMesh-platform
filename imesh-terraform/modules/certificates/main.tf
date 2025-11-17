resource "kubernetes_secret" "nats_server_cert" {
  metadata {
    name      = "nats-server-cert"
    namespace = var.namespaces.v2_deps
  }

  data = {
    "server-cert.pem" = tls_locally_signed_cert.nats.cert_pem
    "server-key.pem"  = tls_private_key.nats.private_key_pem
    "rootCA.pem"      = tls_self_signed_cert.ca.cert_pem
  }
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "iMesh CA"
    organization = "iMesh"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true
}

resource "tls_private_key" "nats" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "nats" {
  private_key_pem = tls_private_key.nats.private_key_pem

  subject {
    common_name = "nats.v2-deps.svc.cluster.local"
  }

  dns_names = [
    "localhost",
    "nats.v2-deps",
    "nats.v2-deps.svc.cluster.local",
    "services.${var.domains[2]}"
  ]
}

resource "tls_locally_signed_cert" "nats" {
  cert_request_pem   = tls_cert_request.nats.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "kubectl_manifest" "cert_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: pulak.das@imesh.ai
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
            - name: app
              namespace: ${var.namespaces.v2}
              kind: Gateway
            - name: keycloak
              namespace: ${var.namespaces.v2_deps}
              kind: Gateway
YAML

  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.13.3"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "createNamespaceResource"
    value = "false"
  }
}
