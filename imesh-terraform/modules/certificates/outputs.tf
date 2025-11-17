output "certificate_secrets" {
  description = "Generated certificate secrets"
  value = {
    nats_server_cert = kubernetes_secret.nats_server_cert.metadata[0].name
  }
}

output "ca_certificate" {
  description = "CA certificate PEM"
  value       = tls_self_signed_cert.ca.cert_pem
  sensitive   = true
}

output "nats_certificate" {
  description = "NATS server certificate PEM"
  value       = tls_locally_signed_cert.nats.cert_pem
  sensitive   = true
}

output "nats_private_key" {
  description = "NATS server private key PEM"
  value       = tls_private_key.nats.private_key_pem
  sensitive   = true
}

output "cert_manager_status" {
  description = "Cert Manager Helm release status"
  value       = helm_release.cert_manager.status
}

output "cluster_issuer_name" {
  description = "Cluster issuer name"
  value       = "letsencrypt-prod"
}
