# 0-infra-base

Layer 0: Manual bootstrap repository for infrastructure automation

This repository serves as the single source of truth for infrastructure setup. All manual work is done here, and everything else is automated via Terraform and GitHub Actions with self-hosted runners.

## Architecture

- **Hashicorp Vault**: Secure secrets management (Docker-based)
- **Terraform**: Infrastructure as Code for GitHub repository management
- **Self-hosted GitHub Runner**: Automation bridge to lab infrastructure

## Quick Start

### 1. Start Vault

```bash
docker-compose up -d
```

### 2. Bootstrap Vault and Secrets

**Linux/Mac:**
```bash
chmod +x scripts/vault-setup.sh
./scripts/vault-setup.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\vault-setup.ps1
```

Follow the interactive menu to:
- Initialize Vault (first time)
- Unseal Vault
- Store GitHub credentials
- Setup AppRole for Terraform

### 3. Initialize Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
```

### 4. Customize and Deploy

Edit [terraform/repositories.tf](terraform/repositories.tf) to define your repositories, then:

```bash
terraform plan
terraform apply
```

## Documentation

- **[BOOTSTRAP.md](BOOTSTRAP.md)**: Comprehensive setup guide with all manual steps
- **[terraform/](terraform/)**: Terraform configuration for GitHub repository management
- **[vault/config/](vault/config/)**: Vault configuration files

## Repository Structure

```
.
├── docker-compose.yml          # Vault container setup
├── BOOTSTRAP.md                # Detailed setup instructions
├── terraform/
│   ├── main.tf                 # Terraform provider configuration
│   ├── variables.tf            # Input variables
│   ├── repositories.tf         # GitHub repository definitions
│   ├── outputs.tf              # Terraform outputs
│   └── terraform.tfvars.example # Example variables file
├── vault/
│   └── config/
│       └── vault.hcl          # Vault server configuration
└── scripts/
    ├── vault-setup.sh         # Vault setup helper (Linux/Mac)
    └── vault-setup.ps1        # Vault setup helper (Windows)
```

## Security Notes

- Vault data is stored in `./vault/data/` (gitignored)
- Unseal keys and root token must be stored securely
- GitHub tokens are stored in Vault, never in code
- All sensitive files are in `.gitignore`

## Next Steps

1. Review [BOOTSTRAP.md](BOOTSTRAP.md) for detailed setup
2. Configure your self-hosted GitHub runner
3. Customize repository definitions in [terraform/repositories.tf](terraform/repositories.tf)
4. Set up GitHub Actions workflows in created repos

## Source Material

- https://blog.ricardof.dev/setup-self-hosted-github-action-runner-in-minutes/
- https://gist.github.com/lbssousa/bb081e35d483520928033b2797133d5e
- https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
- https://github.com/hassio-addons/workflows/tree/main/.github
