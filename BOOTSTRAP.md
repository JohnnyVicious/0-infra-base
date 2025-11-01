# Bootstrap Guide

This guide covers the manual setup steps required to bootstrap your infrastructure automation.

## Prerequisites

- Docker and Docker Compose installed
- GitHub account with admin access
- Git installed
- Terraform installed (v1.0+)

## Step 1: Set Up Hashicorp Vault

### 1.1 Start Vault

```bash
docker-compose up -d
```

### 1.2 Initialize Vault

Check Vault status:
```bash
docker exec -it vault vault status
```

Initialize Vault (first time only):
```bash
docker exec -it vault vault operator init
```

**IMPORTANT**: Save the unseal keys and root token securely! You'll see output like:
```
Unseal Key 1: xxxxx
Unseal Key 2: xxxxx
Unseal Key 3: xxxxx
Unseal Key 4: xxxxx
Unseal Key 5: xxxxx

Initial Root Token: s.xxxxx
```

Store these in a secure location (password manager, encrypted file, etc.). You need 3 out of 5 keys to unseal Vault.

### 1.3 Unseal Vault

Every time Vault restarts, you need to unseal it with 3 of the 5 keys:

```bash
docker exec -it vault vault operator unseal
# Enter key 1
docker exec -it vault vault operator unseal
# Enter key 2
docker exec -it vault vault operator unseal
# Enter key 3
```

### 1.4 Login to Vault

```bash
docker exec -it vault vault login
# Enter your root token
```

### 1.5 Access Vault UI

Open your browser and navigate to: http://localhost:8200

Login with your root token.

## Step 2: Configure Vault for GitHub Secrets

### 2.1 Enable KV Secrets Engine

```bash
docker exec -it vault vault secrets enable -path=github kv-v2
```

### 2.2 Store GitHub Personal Access Token

Create a GitHub Personal Access Token (Classic) with these permissions:
- `repo` (Full control of private repositories)
- `admin:org` (if managing organization repos)
- `delete_repo` (if Terraform should be able to delete repos)
- `workflow` (for GitHub Actions secrets)

Store the token in Vault:
```bash
docker exec -it vault vault kv put github/terraform token=ghp_your_token_here
```

### 2.3 Store GitHub Owner

```bash
docker exec -it vault vault kv put github/config owner=your-github-username-or-org
```

### 2.4 Create Vault Policy for Terraform

```bash
docker exec -it vault vault policy write terraform-policy - <<EOF
path "github/*" {
  capabilities = ["read", "list"]
}
EOF
```

### 2.5 Enable AppRole Auth (for automation)

```bash
docker exec -it vault vault auth enable approle

docker exec -it vault vault write auth/approle/role/terraform \
    secret_id_ttl=0 \
    token_ttl=20m \
    token_max_ttl=30m \
    policies="terraform-policy"
```

Get Role ID and Secret ID:
```bash
# Get Role ID
docker exec -it vault vault read auth/approle/role/terraform/role-id

# Generate Secret ID
docker exec -it vault vault write -f auth/approle/role/terraform/secret-id
```

Save these for use with Terraform and your self-hosted runner.

## Step 3: Set Up Self-Hosted GitHub Runner

### 3.1 Create Runner in GitHub

1. Go to your repository settings
2. Navigate to Actions > Runners
3. Click "New self-hosted runner"
4. Follow the instructions for your OS

### 3.2 Configure Runner with Vault Access

Set environment variables for the runner to access Vault:

```bash
export VAULT_ADDR=http://localhost:8200
export VAULT_ROLE_ID=your-role-id
export VAULT_SECRET_ID=your-secret-id
```

### 3.3 Start the Runner

```bash
./run.sh
```

For Windows:
```cmd
run.cmd
```

## Step 4: Initialize Terraform

### 4.1 Create terraform.tfvars

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values.

### 4.2 Export Vault Secrets for Terraform

Option 1 - Direct token (for testing):
```bash
export TF_VAR_github_token=$(docker exec -it vault vault kv get -field=token github/terraform)
export TF_VAR_github_owner=$(docker exec -it vault vault kv get -field=owner github/config)
```

Option 2 - Using Vault provider (recommended):
Create a `vault-integration.tf` to pull secrets directly from Vault during terraform runs.

### 4.3 Initialize Terraform

```bash
terraform init
```

### 4.4 Plan and Apply

```bash
terraform plan
terraform apply
```

## Step 5: Verify Setup

1. Check that Vault is running: `docker ps`
2. Check Vault status: `docker exec -it vault vault status`
3. Verify Terraform can read from Vault
4. Verify GitHub runner is connected in GitHub UI

## Maintenance

### Backing Up Vault Data

The `./vault/data` directory contains your Vault data. Back this up regularly:

```bash
tar -czf vault-backup-$(date +%Y%m%d).tar.gz ./vault/data
```

### Unsealing Vault After Restart

If your Docker host restarts, Vault will be sealed. Follow Step 1.3 to unseal it.

### Rotating GitHub Token

1. Create new GitHub token
2. Update in Vault: `docker exec -it vault vault kv put github/terraform token=new_token`
3. No Terraform changes needed - it reads from Vault

## Security Best Practices

1. **Never commit secrets** - Vault data and tokens are in `.gitignore`
2. **Use HTTPS in production** - The current config uses HTTP for simplicity
3. **Limit token permissions** - Only grant necessary GitHub permissions
4. **Rotate tokens regularly** - Especially if compromised
5. **Enable audit logging** in Vault for production use
6. **Use separate Vault namespaces** for different environments
7. **Implement backup strategy** for Vault data
8. **Consider using Vault auto-unseal** with cloud KMS in production

## Troubleshooting

### Vault is sealed
Run unseal commands (Step 1.3)

### Cannot connect to Vault
Check if container is running: `docker ps`
Check logs: `docker logs vault`

### Terraform cannot authenticate to GitHub
Verify token in Vault: `docker exec -it vault vault kv get github/terraform`
Check token permissions in GitHub

### Runner cannot access Vault
Verify VAULT_ADDR is correct
Check AppRole credentials are valid

## Next Steps

1. Customize `terraform/repositories.tf` to create your repositories
2. Set up GitHub Actions workflows in created repositories
3. Configure additional secrets in Vault as needed
4. Set up monitoring for Vault and your runner
