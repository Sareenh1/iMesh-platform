variable "namespaces" {
  description = "Namespaces for gateways"
  type = object({
    v2      = string
    v2_deps = string
  })
}

variable "domain" {
  description = "Base domain"
  type        = string
}
