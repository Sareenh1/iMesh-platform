variable "namespaces" {
  description = "Namespaces for certificate secrets"
  type = object({
    v2      = string
    v2_deps = string
  })
}

variable "domain" {
  description = "Base domain"
  type        = string
}

variable "email" {
  description = "Email for certificate registration"
  type        = string
}
