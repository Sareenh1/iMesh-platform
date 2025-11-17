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
    common_name = "nats.${var.namespaces.v2_deps}.svc.cluster.local"
  }

  dns_names = [
    "localhost",
    "nats.${var.namespaces.v2_deps}",
    "nats.${var.namespaces.v2_deps}.svc.cluster.local",
    "services.${var.domain}"
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
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email = var.email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-account-key"
        }
        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [
                  {
                    name = "app"
                    namespace = var.namespaces.v2
                    kind = "Gateway"
                  },
                  {
                    name = "keycloak"
                    namespace = var.namespaces.v2_deps
                    kind = "Gateway"
                  }
                ]
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
