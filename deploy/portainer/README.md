# Portainer Stack Definitions

This directory stores stack definitions that can be deployed to Portainer via CI/CD. Each stack lives in its own subdirectory and provides:

- `docker-compose.yml` (required): the manifest consumed by the GitHub Action.
- `stack.env` (optional): environment variables injected during deployment.
- `README.md` (optional): human context, prerequisites, and customization tips.

## Deploying with GitHub Actions

Use the [Portainer Stack Deployer](https://github.com/marketplace/actions/portainer-stack-deployer) GitHub Action and point it to the desired stack files. Example:

```yaml
- uses: msfidelis/portainer-stack-deploy@v2
  with:
    url: ${{ secrets.PORTAINER_URL }}
    username: ${{ secrets.PORTAINER_USERNAME }}
    password: ${{ secrets.PORTAINER_PASSWORD }}
    endpoint: ${{ vars.PORTAINER_ENDPOINT }}
    stack_name: vault
    compose_file: deploy/portainer/stacks/vault/docker-compose.yml
    env_file: deploy/portainer/stacks/vault/stack.env
    action: deploy
```

Store sensitive inputs (Portainer credentials, Harbor admin password, etc.) in repository or organization secrets.

## Available Stacks

| Stack | Purpose | Compose file |
|-------|---------|--------------|
| Vault | HashiCorp Vault for secrets management | `stacks/vault/docker-compose.yml` |
| Harbor | Container registry and cache | `stacks/harbor/docker-compose.yml` |

Add additional stacks by creating new subdirectories under `stacks/`.
