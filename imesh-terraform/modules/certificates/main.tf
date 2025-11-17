# Install cert-manager with proper configuration
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.13.3"  # Use stable version
  timeout    = 600

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "createNamespaceResource"
    value = "false"
  }

  wait = true
}

# Simple self-signed certificates for development
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

resource "kubernetes_secret" "ca_cert" {
  metadata {
    name      = "ca-certificate"
    namespace = var.namespaces.v2_deps
  }

  data = {
    "ca.crt" = tls_self_signed_cert.ca.cert_pem
    "ca.key" = tls_private_key.ca.private_key_pem
  }
}
