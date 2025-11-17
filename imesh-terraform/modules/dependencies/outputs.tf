output "mongodb_url" {
  description = "MongoDB connection URL"
  value       = "mongodb://mongodb.${var.namespace}.svc.cluster.local:27017"
}

output "redis_url" {
  description = "Redis connection URL"
  value       = "redis-master.${var.namespace}.svc.cluster.local"
}

output "nats_url" {
  description = "NATS connection URL"
  value       = "nats://nats.${var.namespace}.svc.cluster.local:4222"
}

output "keycloak_url" {
  description = "Keycloak service URL"
  value       = "http://keycloak.${var.namespace}.svc.cluster.local"
}

output "mongodb_status" {
  description = "MongoDB Helm release status"
  value       = helm_release.mongodb.status
}

output "redis_status" {
  description = "Redis Helm release status"
  value       = helm_release.redis.status
}

output "nats_status" {
  description = "NATS Helm release status"
  value       = helm_release.nats.status
}
