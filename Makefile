.PHONY: help vault-up vault-down vault-status vault-logs vault-setup terraform-init terraform-plan terraform-apply clean

VAULT_COMPOSE := deploy/portainer/stacks/vault/docker-compose.yml
VAULT_ENV := deploy/portainer/stacks/vault/stack.env

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Vault commands
vault-up: ## Start Vault container
	docker-compose --env-file $(VAULT_ENV) -f $(VAULT_COMPOSE) up -d
	@echo "Vault is starting... Wait a few seconds, then run 'make vault-status'"

vault-down: ## Stop Vault container
	docker-compose -f $(VAULT_COMPOSE) down

vault-status: ## Check Vault status
	docker exec -it vault vault status || echo "Vault may be sealed or not initialized"

vault-logs: ## View Vault logs
	docker logs -f vault

vault-setup: ## Run interactive Vault setup script
	@if [ -f scripts/vault-setup.sh ]; then \
		chmod +x scripts/vault-setup.sh && ./scripts/vault-setup.sh; \
	else \
		echo "Run this in PowerShell: .\scripts\vault-setup.ps1"; \
	fi

vault-unseal: ## Unseal Vault (interactive)
	@echo "Unsealing Vault - you need to enter 3 different unseal keys"
	@docker exec -it vault vault operator unseal
	@docker exec -it vault vault operator unseal
	@docker exec -it vault vault operator unseal

vault-login: ## Login to Vault
	docker exec -it vault vault login

# Terraform commands
terraform-init: ## Initialize Terraform
	cd terraform && terraform init

terraform-plan: ## Run Terraform plan
	cd terraform && terraform plan

terraform-apply: ## Apply Terraform changes
	cd terraform && terraform apply

terraform-destroy: ## Destroy Terraform-managed resources (use with caution!)
	cd terraform && terraform destroy

# Utility commands
clean: ## Clean up temporary files
	rm -rf terraform/.terraform
	rm -f terraform/.terraform.lock.hcl
	rm -f terraform/terraform.tfstate.backup

backup-vault: ## Create backup of Vault data
	@mkdir -p backups
	tar -czf backups/vault-backup-$$(date +%Y%m%d-%H%M%S).tar.gz deploy/portainer/stacks/vault/data
	@echo "Backup created in backups/"

# Combined workflow
bootstrap: vault-up ## Complete bootstrap process
	@echo "Waiting for Vault to start..."
	@sleep 5
	@echo ""
	@echo "Next steps:"
	@echo "1. Run 'make vault-setup' to configure Vault"
	@echo "2. Run 'make terraform-init' to initialize Terraform"
	@echo "3. Edit terraform/repositories.tf to define your repos"
	@echo "4. Run 'make terraform-apply' to create repositories"
