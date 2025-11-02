# Harbor Stack

Container registry and caching service built on Harbor. This stack uses the Bitnami-maintained Harbor images to simplify deployment under Portainer.

## Files

- `docker-compose.yml` – Harbor microservices defined for Portainer.
- `stack.env` – Default environment variables. Update with strong secrets and the hostname you will publish.

Create TLS certificates and drop them into `proxy_certs` (see volumes) before exposing Harbor over HTTPS in production.

## Configuration Tips

- Generate unique 32+ byte secrets for `CORE_SECRET`, `JOBSERVICE_SECRET`, `REGISTRY_HTTP_SECRET`, and `TRIVY_SECRET`.
- Replace the default admin password and make sure the host in `HARBOR_HOSTNAME` matches the DNS name that clients use.
- Attach persistent storage by replacing the named volumes with bind mounts if you need to manage data locations explicitly.
- Review Bitnami Harbor documentation for additional tunables: https://docs.bitnami.com/container/apps/harbor/

## Local Smoke Test

```bash
docker-compose -f deploy/portainer/stacks/harbor/docker-compose.yml --env-file deploy/portainer/stacks/harbor/stack.env up -d
```

When testing locally without TLS, set `HARBOR_HTTPS_PORT` to a free port and access the portal via `http://localhost:${HARBOR_HTTP_PORT}`.
