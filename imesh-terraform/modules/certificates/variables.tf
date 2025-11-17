variable "namespaces" {
  description = "Namespaces for certificate secrets"
  type = object({
    v2      = string
    v2_deps = string
  })
}

variable "domains" {
  description = "Domains for certificate generation"
  type        = list(string)
}
