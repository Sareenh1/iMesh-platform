output "mongodb_password" {
  description = "MongoDB password"
  value       = var.mongodb_password
  sensitive   = true
}

output "redis_password" {
  description = "Redis password"
  value       = var.redis_password
  sensitive   = true
}
