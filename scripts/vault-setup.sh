#!/usr/bin/env bash

set -euo pipefail

VAULT_ADDR=${VAULT_ADDR:-http://localhost:8200}
VAULT_CONTAINER=${VAULT_CONTAINER:-vault}

echo "=== Vault Setup Helper ==="
echo "Vault Address: $VAULT_ADDR"
echo ""

# Function to execute vault commands in container
vault_exec() {
    docker exec -it "$VAULT_CONTAINER" vault "$@"
}

# Check if Vault is running
if ! docker ps --format '{{.Names}}' | grep -Fxq "$VAULT_CONTAINER"; then
    echo "Error: Vault container is not running"
    echo "Start it with: make vault-up"
    exit 1
fi

echo "1. Checking Vault status..."
vault_exec status || echo "Vault may be sealed or not initialized"
echo ""

# Menu
PS3="Select an option: "
options=(
    "Initialize Vault (first time only)"
    "Unseal Vault"
    "Login to Vault"
    "Setup GitHub secrets"
    "Setup AppRole for Terraform"
    "Export Terraform variables"
    "View GitHub token"
    "Exit"
)

select opt in "${options[@]}"
do
    case $opt in
        "Initialize Vault (first time only)")
            echo "Initializing Vault..."
            vault_exec operator init
            echo ""
            echo "IMPORTANT: Save the unseal keys and root token in a secure location!"
            echo ""
            ;;
        "Unseal Vault")
            echo "Unsealing Vault (you'll need to run this 3 times with different keys)..."
            vault_exec operator unseal
            ;;
        "Login to Vault")
            echo "Logging in to Vault..."
            vault_exec login
            ;;
        "Setup GitHub secrets")
            echo "Setting up GitHub secrets in Vault..."

            # Enable secrets engine
            echo "Enabling KV secrets engine at github/..."
            vault_exec secrets enable -path=github kv-v2 || echo "Secrets engine may already be enabled"

            # Get GitHub token
            read -rsp "Enter your GitHub Personal Access Token: " GITHUB_TOKEN || true
            echo ""
            if [[ -z "${GITHUB_TOKEN:-}" ]]; then
                echo "Token cannot be empty. Aborting."
                unset GITHUB_TOKEN
                continue
            fi

            # Get GitHub owner
            read -rp "Enter your GitHub username or organization: " GITHUB_OWNER
            if [[ -z "${GITHUB_OWNER:-}" ]]; then
                echo "Owner cannot be empty. Aborting."
                unset GITHUB_OWNER
                continue
            fi

            # Store in Vault
            echo "Storing GitHub token in Vault..."
            vault_exec kv put github/terraform token="$GITHUB_TOKEN"

            echo "Storing GitHub owner in Vault..."
            vault_exec kv put github/config owner="$GITHUB_OWNER"

            unset GITHUB_TOKEN
            unset GITHUB_OWNER

            echo "GitHub secrets configured successfully!"
            ;;
        "Setup AppRole for Terraform")
            echo "Setting up AppRole authentication for Terraform..."

            # Enable AppRole
            vault_exec auth enable approle || echo "AppRole may already be enabled"

            # Create policy
            echo "Creating Terraform policy..."
            vault_exec policy write terraform-policy - <<EOF
path "github/*" {
  capabilities = ["read", "list"]
}
EOF

            # Create AppRole
            echo "Creating Terraform AppRole..."
            vault_exec write auth/approle/role/terraform \
                secret_id_ttl=0 \
                token_ttl=20m \
                token_max_ttl=30m \
                policies="terraform-policy"

            # Get Role ID
            echo ""
            echo "=== Role ID ==="
            vault_exec read auth/approle/role/terraform/role-id

            echo ""
            echo "=== Secret ID ==="
            vault_exec write -f auth/approle/role/terraform/secret-id

            echo ""
            echo "Save these credentials for your CI/CD system!"
            ;;
        "Export Terraform variables")
            echo "Exporting Terraform variables..."
            echo ""
            echo "Run these commands in your terminal:"
            echo ""
            echo "export VAULT_ADDR=$VAULT_ADDR"
            printf 'export TF_VAR_github_token=$(docker exec "%s" vault kv get -field=token github/terraform)\n' "$VAULT_CONTAINER"
            printf 'export TF_VAR_github_owner=$(docker exec "%s" vault kv get -field=owner github/config)\n' "$VAULT_CONTAINER"
            echo ""
            ;;
        "View GitHub token")
            echo "Retrieving GitHub token from Vault..."
            vault_exec kv get github/terraform
            ;;
        "Exit")
            echo "Goodbye!"
            break
            ;;
        *)
            echo "Invalid option $REPLY"
            ;;
    esac
    echo ""
done
