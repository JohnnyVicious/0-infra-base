# 0-infra-base

Layer 0: Manual bootstrap repository for infrastructure automation

This repository serves as the single source of truth for infrastructure setup. All manual work is done here, and everything else is automated via Terraform and GitHub Actions with self-hosted runners.

## Architecture

- **Hashicorp Vault**: Secure secrets management (Docker-based)
- **Terraform**: Infrastructure as Code for GitHub repository management
- **Self-hosted GitHub Runner**: Automation bridge to lab infrastructure
- **Automated Releases**: Semantic versioning with conventional commits

## Quick Start

### 1. Start Vault

```bash
make vault-up
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
- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Contribution guidelines and release workflow
- **[.github/renovate.md](.github/renovate.md)**: Renovate Bot configuration and usage
- **[terraform/](terraform/)**: Terraform configuration for GitHub repository management
- **[deploy/portainer/](deploy/portainer/)**: Portainer stack definitions (Vault, Harbor, ...)

## Repository Structure

```
.
├── BOOTSTRAP.md                # Detailed setup instructions
├── CONTRIBUTING.md             # Contribution guide
├── Makefile                    # Common commands
├── .releaserc.json            # Semantic release configuration
├── renovate.json              # Renovate Bot configuration
├── deploy/
│   └── portainer/
│       ├── README.md               # Stack deployment guide
│       └── stacks/
│           ├── harbor/
│           │   ├── docker-compose.yml
│           │   ├── README.md
│           │   └── stack.env
│           └── vault/
│               ├── docker-compose.yml
│               ├── README.md
│               ├── config/
│               │   └── vault.hcl
│               └── stack.env
├── .github/
│   ├── workflows/
│   │   ├── release.yml        # Automated releases
│   │   ├── pr-labeler.yml     # PR auto-labeling
│   │   ├── label-sync.yml     # Label synchronization
│   │   ├── renovate-validate.yml # Renovate config validation
│   │   └── codeql.yml         # CodeQL security scanning
│   ├── codeql/
│   │   └── codeql-config.yml  # CodeQL configuration
│   ├── pull_request_template.md
│   ├── labels.yml             # Repository labels
│   └── renovate.md            # Renovate documentation
├── terraform/
│   ├── main.tf                 # Terraform provider configuration
│   ├── variables.tf            # Input variables
│   ├── repositories.tf         # GitHub repository definitions
│   ├── outputs.tf              # Terraform outputs
│   └── terraform.tfvars.example # Example variables file
└── scripts/
    ├── vault-setup.sh         # Vault setup helper (Linux/Mac)
    └── vault-setup.ps1        # Vault setup helper (Windows)
```

## Security

### Security Scanning
- **CodeQL**: Automated security scanning on all PRs and weekly
- **Dependency Scanning**: Renovate monitors for security vulnerabilities
- **Branch Protection**: CodeQL required for PR merges

### Security Best Practices
- Vault data is stored in `deploy/portainer/stacks/vault/data/` (gitignored)
- Unseal keys and root token must be stored securely
- GitHub tokens are stored in Vault, never in code
- All sensitive files are in `.gitignore`
- Docker images and GitHub Actions are digest-pinned

## Automation

This repository uses several automation tools:

### Semantic Versioning
Automated releases based on conventional commits. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

**PR Title Format**:
- `feat:` → minor version bump (0.x.0)
- `fix:` → patch version bump (0.0.x)
- `feat!:` → major version bump (x.0.0)

### Dependency Updates
[Renovate Bot](.github/renovate.md) automatically creates PRs for:
- Docker image updates
- Terraform provider updates
- GitHub Actions updates
- Security patches

Runs weekly (Mondays) and creates a Dependency Dashboard issue.

## Next Steps

1. Review [BOOTSTRAP.md](BOOTSTRAP.md) for detailed setup
2. Configure your self-hosted GitHub runner
3. Customize repository definitions in [terraform/repositories.tf](terraform/repositories.tf)
4. Set up GitHub Actions workflows in created repos
5. Read [CONTRIBUTING.md](CONTRIBUTING.md) before making changes

## Source Material

- https://blog.ricardof.dev/setup-self-hosted-github-action-runner-in-minutes/
- https://gist.github.com/lbssousa/bb081e35d483520928033b2797133d5e
- https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
- https://github.com/hassio-addons/workflows/tree/main/.github
