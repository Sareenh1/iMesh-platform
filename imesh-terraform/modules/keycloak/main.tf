resource "random_password" "graphql_backend_secret" {
  length  = 32
  special = true
}

resource "null_resource" "configure_keycloak" {
  triggers = {
    keycloak_pod = "keycloak-0" # StatefulSet pod name
  }

  provisioner "local-exec" {
    command = <<EOF
#!/bin/bash
set -e

echo "Waiting for Keycloak to be ready..."
kubectl wait --for=condition=ready pod/keycloak-0 -n ${var.namespace} --timeout=600s

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

# Create istio-manager realm
curl -s -X POST \
  http://localhost:8080/admin/realms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "istio-manager",
    "enabled": true,
    "displayName": "Istio Manager"
  }'

# Create UI client in istio-manager realm
curl -s -X POST \
  http://localhost:8080/admin/realms/istio-manager/clients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "ui",
    "enabled": true,
    "publicClient": true,
    "redirectUris": ["https://app.${var.domain}/*"],
    "webOrigins": ["*"]
  }'

# Create graphql-backend client in master realm
GRAPHQL_CLIENT_ID=$(curl -s -X POST \
  http://localhost:8080/admin/realms/master/clients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "graphql-backend",
    "enabled": true,
    "publicClient": false,
    "serviceAccountsEnabled": true,
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

  depends_on = [kubernetes_stateful_set.keycloak]
}
