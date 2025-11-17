# Deploy all modules EXCEPT gateways for now
module "certificates" {
  # ... existing config
}

module "dependencies" {
  # ... existing config
}

module "keycloak" {
  # ... existing config
}

module "applications" {
  # ... existing config
}

module "agent" {
  # ... existing config
}

# COMMENT OUT GATEWAYS FOR NOW
/*
module "gateways" {
  source = "./modules/gateways"
  
  namespaces = {
    v2      = kubernetes_namespace.v2.metadata[0].name
    v2_deps = kubernetes_namespace.v2_deps.metadata[0].name
  }
  
  domain = var.domain
  
  depends_on = [
    module.certificates,
    module.dependencies,
    module.applications,
    module.agent
  ]
}
*/
