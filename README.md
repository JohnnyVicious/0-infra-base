# 0-infra-base

Infrastructure bootstrap repo for Vault, Terraform, and supporting automation. Everything else hangs off this layer.

## TL;DR
- **Vault** via Portainer stack (`deploy/portainer/stacks/vault/`)
- **Harbor** registry stack (`deploy/portainer/stacks/harbor/`)
- **Terraform** configuration for GitHub org (`terraform/`)
- **Automation**: semantic-release, Renovate nightly, CodeQL, PR labelling

## Getting Started
1. `make vault-up` then run `scripts/vault-setup.sh` (or `.ps1`) to initialise Vault and store GitHub creds.
2. Copy `terraform/terraform.tfvars.example` to `terraform.tfvars`, fill in owner/token (pull from Vault), then run `terraform init`.
3. Define repos in `terraform/repositories.tf`, run `terraform plan` / `apply`.
4. Deploy additional services through Portainer using the compose files under `deploy/portainer/stacks/`.

Full instructions live in [BOOTSTRAP.md](BOOTSTRAP.md).

## Automation Cheatsheet
- Releases: `.github/workflows/release.yml` (semantic-release + changelog PR)
- Dependencies: nightly Renovate run at 03:00 UTC (`.github/workflows/renovate-run.yml`, needs `RENOVATE_TOKEN`)
- Security: CodeQL (`.github/workflows/codeql.yml`)
- PR hygiene: label sync + conventional commit PR labeler

## Useful Docs
- [BOOTSTRAP.md](BOOTSTRAP.md) – end-to-end setup
- [CONTRIBUTING.md](CONTRIBUTING.md) – workflow rules and release process
- [agents.md](agents.md) – catalogue of automated workflows
- [deploy/portainer/README.md](deploy/portainer/README.md) – Portainer stack guide
