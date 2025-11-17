output "certificate_secrets" {
  description = "Generated certificate secrets"
  value = {
    nats_server_cert = kubernetes_secret.nats_server_cert.metadata[0].name
  }
}
