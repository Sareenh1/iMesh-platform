output "nginx_ingress_status" {
  description = "NGINX Ingress Helm release status"
  value       = helm_release.nginx_ingress.status
}

output "app_ingress_url" {
  description = "Application ingress URL"
  value       = "https://app.${var.domain}"
}

output "services_ingress_url" {
  description = "Services ingress URL"
  value       = "https://services.${var.domain}"
}

output "keycloak_ingress_url" {
  description = "Keycloak ingress URL"
  value       = "https://auth.${var.domain}"
}

output "ingress_class" {
  description = "Ingress class name"
  value       = "nginx"
}

output "ingress_controller" {
  description = "Ingress controller information"
  value = {
    name      = "nginx-ingress"
    namespace = "ingress-nginx"
    status    = helm_release.nginx_ingress.status
  }
}
