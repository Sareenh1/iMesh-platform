resource "kubernetes_secret" "keycloak_client_secrets" {
  metadata {
    name      = "keycloak-client-secrets"
    namespace = var.namespace
  }

  data = {
    graphql-backend-secret = random_password.graphql_backend_secret.result
  }
}

resource "random_password" "graphql_backend_secret" {
  length  = 32
  special = true
}

resource "null_resource" "configure_keycloak" {
  triggers = {
    keycloak_pod = kubernetes_pod.keycloak_wait.id
  }

  provisioner "local-exec" {
    command = <<EOF
#!/bin/bash
set -e

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to be ready..."
kubectl wait --for=condition=ready pod -l app=keycloak -n ${var.namespace} --timeout=600s

# Setup port forwarding
kubectl port-forward -n ${var.namespace} svc/keycloak 8080:80 &
PORT_FORWARD_PID=$!
sleep 10

# Get admin token
TOKEN=$(curl -s -X POST \
  http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${var.admin_user}" \
  -d "password=${var.admin_pass}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

# Create realm
curl -s -X POST \
  http://localhost:8080/admin/realms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "${var.realm_config.name}",
    "enabled": true,
    "displayName": "${var.realm_config.display_name}"
  }'

# Create UI client
curl -s -X POST \
  http://localhost:8080/admin/realms/${var.realm_config.name}/clients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "${var.clients.ui.client_id}",
    "enabled": true,
    "publicClient": ${var.clients.ui.public_client},
    "redirectUris": ${jsonencode(var.clients.ui.redirect_uris)},
    "webOrigins": ${jsonencode(var.clients.ui.web_origins)}
  }'

# Create graphql-backend client
GRAPHQL_CLIENT_ID=$(curl -s -X POST \
  http://localhost:8080/admin/realms/master/clients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "${var.clients.graphql_backend.client_id}",
    "enabled": true,
    "publicClient": ${var.clients.graphql_backend.public_client},
    "serviceAccountsEnabled": true,
    "authorizationServicesEnabled": false,
    "standardFlowEnabled": false,
    "directAccessGrantsEnabled": false
  }' | jq -r '.id')

# Set client secret
curl -s -X PUT \
  "http://localhost:8080/admin/realms/master/clients/$GRAPHQL_CLIENT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"secret\": \"${random_password.graphql_backend_secret.result}\"
  }"

# Get service account user ID
SERVICE_ACCOUNT_ID=$(curl -s \
  "http://localhost:8080/admin/realms/master/clients/$GRAPHQL_CLIENT_ID/service-account-user" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.id')

# Get realm-management client ID
REALM_MGMT_CLIENT_ID=$(curl -s \
  "http://localhost:8080/admin/realms/master/clients?clientId=realm-management" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

# Assign create-realm role
CREATE_REALM_ROLE_ID=$(curl -s \
  "http://localhost:8080/admin/realms/master/clients/$REALM_MGMT_CLIENT_ID/roles/create-realm" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.id')

curl -s -X POST \
  "http://localhost:8080/admin/realms/master/users/$SERVICE_ACCOUNT_ID/role-mappings/clients/$REALM_MGMT_CLIENT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\": \"$CREATE_REALM_ROLE_ID\", \"name\": \"create-realm\"}]"

# Assign admin role
ADMIN_ROLE_ID=$(curl -s \
  "http://localhost:8080/admin/realms/master/clients/$REALM_MGMT_CLIENT_ID/roles/admin" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.id')

curl -s -X POST \
  "http://localhost:8080/admin/realms/master/users/$SERVICE_ACCOUNT_ID/role-mappings/clients/$REALM_MGMT_CLIENT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\": \"$ADMIN_ROLE_ID\", \"name\": \"admin\"}]"

# Stop port forwarding
kill $PORT_FORWARD_PID

echo "Keycloak configuration completed!"
EOF

    interpreter = ["bash", "-c"]
  }

  depends_on = [helm_release.dependencies]
}

resource "kubernetes_pod" "keycloak_wait" {
  metadata {
    name      = "keycloak-wait-helper"
    namespace = var.namespace
  }

  spec {
    container {
      name    = "wait"
      image   = "bitnami/kubectl:latest"
      command = ["sleep", "3600"]
    }

    restart_policy = "Never"
  }

  depends_on = [helm_release.dependencies]
}

resource "helm_release" "dependencies" {
  name       = "dependencies"
  chart      = "dummy"
  namespace  = var.namespace

  # This is a dummy release to ensure dependencies are created
  set {
    name  = "dummy"
    value = "value"
  }
}
