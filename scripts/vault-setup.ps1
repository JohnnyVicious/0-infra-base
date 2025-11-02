# Vault Setup Helper Script (PowerShell)
# This script helps automate the Vault setup process on Windows

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$VAULT_ADDR = if ($env:VAULT_ADDR) { $env:VAULT_ADDR } else { "http://localhost:8200" }
$VAULT_CONTAINER = if ($env:VAULT_CONTAINER) { $env:VAULT_CONTAINER } else { "vault" }

Write-Host "=== Vault Setup Helper ===" -ForegroundColor Cyan
Write-Host "Vault Address: $VAULT_ADDR"
Write-Host ""

# Function to execute vault commands in container
function Invoke-VaultCommand {
    param([string[]]$Command)
    docker exec -i $VAULT_CONTAINER vault @Command
}

# Check if Vault is running
$running = docker ps --format "{{.Names}}" | Select-String -Pattern $VAULT_CONTAINER
if (-not $running) {
    Write-Host "Error: Vault container is not running" -ForegroundColor Red
    Write-Host "Start it with: make vault-up"
    exit 1
}

Write-Host "1. Checking Vault status..."
try {
    Invoke-VaultCommand @("status")
} catch {
    Write-Host "Vault may be sealed or not initialized" -ForegroundColor Yellow
}
Write-Host ""

# Menu loop
do {
    Write-Host "Select an option:" -ForegroundColor Cyan
    Write-Host "1. Initialize Vault (first time only)"
    Write-Host "2. Unseal Vault"
    Write-Host "3. Login to Vault"
    Write-Host "4. Setup GitHub secrets"
    Write-Host "5. Setup AppRole for Terraform"
    Write-Host "6. Export Terraform variables"
    Write-Host "7. View GitHub token"
    Write-Host "8. Exit"
    Write-Host ""

    $choice = Read-Host "Enter your choice (1-8)"

    switch ($choice) {
        "1" {
            Write-Host "Initializing Vault..." -ForegroundColor Yellow
            Invoke-VaultCommand @("operator", "init")
            Write-Host ""
            Write-Host "IMPORTANT: Save the unseal keys and root token in a secure location!" -ForegroundColor Red
            Write-Host ""
        }
        "2" {
            Write-Host "Unsealing Vault (you'll need to run this 3 times with different keys)..." -ForegroundColor Yellow
            Invoke-VaultCommand @("operator", "unseal")
        }
        "3" {
            Write-Host "Logging in to Vault..." -ForegroundColor Yellow
            Invoke-VaultCommand @("login")
        }
        "4" {
            Write-Host "Setting up GitHub secrets in Vault..." -ForegroundColor Yellow

            # Enable secrets engine
            Write-Host "Enabling KV secrets engine at github/..."
            try {
                Invoke-VaultCommand @("secrets", "enable", "-path=github", "kv-v2")
            } catch {
                Write-Host "Secrets engine may already be enabled" -ForegroundColor Yellow
            }

            # Get GitHub token
            $GITHUB_TOKEN = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
            if (-not $GITHUB_TOKEN) {
                Write-Host "Token cannot be empty. Aborting." -ForegroundColor Red
                Remove-Variable GITHUB_TOKEN -ErrorAction SilentlyContinue
                continue
            }
            $tokenPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($GITHUB_TOKEN)
            $GITHUB_TOKEN_PLAIN = [Runtime.InteropServices.Marshal]::PtrToStringAuto($tokenPtr)

            # Get GitHub owner
            $GITHUB_OWNER = Read-Host "Enter your GitHub username or organization"
            if ([string]::IsNullOrWhiteSpace($GITHUB_OWNER)) {
                Write-Host "Owner cannot be empty. Aborting." -ForegroundColor Red
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPtr)
                Remove-Variable GITHUB_TOKEN -ErrorAction SilentlyContinue
                continue
            }

            # Store in Vault
            Write-Host "Storing GitHub token in Vault..."
            docker exec -i $VAULT_CONTAINER vault kv put github/terraform token="$GITHUB_TOKEN_PLAIN"

            Write-Host "Storing GitHub owner in Vault..."
            Invoke-VaultCommand @("kv", "put", "github/config", "owner=$GITHUB_OWNER")

            Write-Host "GitHub secrets configured successfully!" -ForegroundColor Green
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPtr)
            Remove-Variable GITHUB_TOKEN -ErrorAction SilentlyContinue
            Remove-Variable GITHUB_TOKEN_PLAIN -ErrorAction SilentlyContinue
            Remove-Variable GITHUB_OWNER -ErrorAction SilentlyContinue
        }
        "5" {
            Write-Host "Setting up AppRole authentication for Terraform..." -ForegroundColor Yellow

            # Enable AppRole
            try {
                Invoke-VaultCommand @("auth", "enable", "approle")
            } catch {
                Write-Host "AppRole may already be enabled" -ForegroundColor Yellow
            }

            # Create policy
            Write-Host "Creating Terraform policy..."
            $policy = @'
path "github/*" {
  capabilities = ["read", "list"]
}
'@
            $policy | docker exec -i $VAULT_CONTAINER vault policy write terraform-policy -

            # Create AppRole
            Write-Host "Creating Terraform AppRole..."
            Invoke-VaultCommand @("write", "auth/approle/role/terraform", "secret_id_ttl=0", "token_ttl=20m", "token_max_ttl=30m", "policies=terraform-policy")

            # Get Role ID
            Write-Host ""
            Write-Host "=== Role ID ===" -ForegroundColor Cyan
            Invoke-VaultCommand @("read", "auth/approle/role/terraform/role-id")

            Write-Host ""
            Write-Host "=== Secret ID ===" -ForegroundColor Cyan
            Invoke-VaultCommand @("write", "-f", "auth/approle/role/terraform/secret-id")

            Write-Host ""
            Write-Host "Save these credentials for your CI/CD system!" -ForegroundColor Green
        }
        "6" {
            Write-Host "Exporting Terraform variables..." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Run these commands in your PowerShell terminal:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "`$env:VAULT_ADDR = '$VAULT_ADDR'"
            Write-Host "`$env:TF_VAR_github_token = docker exec $VAULT_CONTAINER vault kv get -field=token github/terraform"
            Write-Host "`$env:TF_VAR_github_owner = docker exec $VAULT_CONTAINER vault kv get -field=owner github/config"
            Write-Host ""
        }
        "7" {
            Write-Host "Retrieving GitHub token from Vault..." -ForegroundColor Yellow
            Invoke-VaultCommand @("kv", "get", "github/terraform")
        }
        "8" {
            Write-Host "Goodbye!" -ForegroundColor Cyan
            exit
        }
        default {
            Write-Host "Invalid option: $choice" -ForegroundColor Red
        }
    }
    Write-Host ""
} while ($true)
