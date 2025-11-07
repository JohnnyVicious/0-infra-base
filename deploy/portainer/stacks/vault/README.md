# Vault Stack

HashiCorp Vault runs as a Portainer stack using the compose file in this directory.

## Files

- `docker-compose.yml` – Vault service definition.
- `config/vault.hcl` – Vault server configuration.
- `stack.env` – Optional environment overrides (currently empty).

Volumes in the compose file mount the sibling `config/`, `data/`, and `logs/` directories. Keep `data/` and `logs/` out of version control—they contain sensitive information and are already gitignored.

## Run & Unseal

Prereqs: Docker Engine and Compose plugin. No Vault CLI required (we show both options).

1) Start Vault

```bash
docker compose -f deploy/portainer/stacks/vault/docker-compose.yml up -d
```

2) Check logs until you see "Vault server started"

```bash
docker logs -f vault
```

3) Initialize Vault (option A: using locally installed Vault CLI)

```bash
export VAULT_ADDR=http://localhost:8200
vault operator init -format=json > init.json
# Keep this file safe. It contains unseal keys and the root token.
```

Unseal with any 3 different keys (default 5/3 Shamir):

```bash
for i in 0 1 2; do
	vault operator unseal "$(jq -r ".unseal_keys_b64[$i]" init.json)"
done
export VAULT_TOKEN="$(jq -r '.root_token' init.json)"
vault status
```

3) Initialize Vault (option B: from inside the container, no local CLI)

```bash
docker exec -it vault sh
# inside container
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init
# Copy three different unseal keys from the output and run:
vault operator unseal
vault operator unseal
vault operator unseal
# Copy the displayed Initial Root Token for later use
exit
```

4) Verify health

```bash
curl http://localhost:8200/v1/sys/health
```

## Notes

- External access: open http://localhost:8200 for the UI. Internally, the service advertises `api_addr` as `http://vault:8200` for container-to-container traffic.
- Do not add an explicit `-config=/vault/config/vault.hcl` to the compose `command`. The image entrypoint already supplies `-config` and duplicating it can cause a double load and a port bind error.
- Data durability: the `data/` directory backs the `file` storage; do not delete it unless you intend to reset Vault.
- https://ambar-thecloudgarage.medium.com/hashicorp-vault-with-docker-compose-0ea2ce1ca5ab is a useful reference.

## Tear Down

```bash
docker compose -f deploy/portainer/stacks/vault/docker-compose.yml down
```
