# Vault Stack

HashiCorp Vault runs as a Portainer stack using the compose file in this directory.

## Files

- `docker-compose.yml` – Vault service definition.
- `config/vault.hcl` – Vault server configuration.
- `stack.env` – Optional environment overrides (currently empty).

Volumes in the compose file mount the sibling `config/`, `data/`, and `logs/` directories. Keep `data/` and `logs/` out of version control—they contain sensitive information and are already gitignored.

## Local Testing

```bash
docker-compose -f deploy/portainer/stacks/vault/docker-compose.yml up -d
# or
docker compose -f deploy/portainer/stacks/vault/docker-compose.yml up -d
```

Next steps (unseal, configure secrets) are described in `BOOTSTRAP.md`.
