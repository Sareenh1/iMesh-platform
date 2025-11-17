output "certificate_secrets" {
  description = "Generated certificate secrets"
  value = {
    nats_server_cert = kubernetes_secret.nats_server_cert.metadata[0].name
  }
}

output "cert_manager_status" {
  description = "Cert Manager Helm release status"
  value       = helm_release.cert_manager.status
}

output "cluster_issuer_name" {
  description = "Cluster issuer name"
  value       = "letsencrypt-prod"
}
