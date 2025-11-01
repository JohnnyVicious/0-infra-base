# Renovate Bot Configuration Guide

This document explains how Renovate is configured for this repository.

## Overview

[Renovate](https://docs.renovatebot.com/) automatically creates pull requests to update dependencies, keeping the repository secure and up-to-date.

## Configuration File

The main configuration is in [renovate.json](../renovate.json) at the repository root.

## What Gets Updated

### 1. Docker Images
- **File**: `docker-compose.yml`
- **Example**: `hashicorp/vault:latest` → `hashicorp/vault:1.15.0`
- **Digest pinning**: Enabled for security
- **Update frequency**: Weekly (Mondays)

### 2. Terraform Providers
- **Files**: `terraform/*.tf`
- **Example**: GitHub provider version updates
- **Grouping**: All providers updated together
- **Commit format**: `chore(terraform): update providers`

### 3. GitHub Actions
- **Files**: `.github/workflows/*.yml`
- **Example**: `actions/checkout@v3` → `actions/checkout@v4`
- **Digest pinning**: Enabled for security
- **Grouping**: All actions updated together
- **Commit format**: `chore(ci): update GitHub Actions`

## Schedule

- **Day**: Monday
- **Time**: Before 6 AM (America/New_York)
- **Stability days**: 3 (waits 3 days after release)
- **Concurrent PRs**: Max 5
- **Hourly limit**: Max 2

## PR Behavior

### Automatic Labeling

Every Renovate PR gets labeled:
- `dependencies` - All dependency updates
- `renovate` - Managed by Renovate
- Type-specific: `docker`, `security`, `major-update`
- `automerge-candidate` - For minor/patch updates

### Commit Messages

Renovate uses **conventional commits**:

```
chore(deps): update hashicorp/vault to v1.15.0
chore(terraform): update Terraform providers
chore(ci): update GitHub Actions
fix(security): update hashicorp/vault [SECURITY]
```

These trigger the appropriate semantic release:
- `chore(deps):` → Patch version (0.0.x) or no release
- `fix(security):` → Patch version (0.0.x)
- Major updates → May use `feat:` prefix

### Grouping Strategy

Updates are grouped logically:

| Group | Contains | PR Title |
|-------|----------|----------|
| Terraform providers | All TF providers | `chore(terraform): update Terraform providers` |
| GitHub Actions | All workflow actions | `chore(ci): update GitHub Actions` |
| Individual Docker | Each image separately | `chore(deps): update hashicorp/vault to v1.15` |

## Security

### Vulnerability Alerts

- **Priority**: High
- **Labels**: `security`, `dependencies`
- **Commit type**: `fix(security):`
- **Review**: Manual (no auto-merge)

### Digest Pinning

All Docker images and GitHub Actions are pinned by digest for security:

```yaml
# Before
image: hashicorp/vault:1.15.0

# After (with digest)
image: hashicorp/vault:1.15.0@sha256:abc123...
```

This prevents:
- Tag mutation attacks
- Unexpected image changes
- Supply chain vulnerabilities

## Dependency Dashboard

Renovate creates an issue titled **"Renovate Dashboard"** showing:
- ✅ Completed updates
- 🟡 Pending updates
- ❌ Failed updates
- ⏸️ Rate-limited updates
- 🔕 Ignored dependencies

Check the dashboard to:
- See all pending updates at a glance
- Trigger updates manually
- Ignore specific dependencies

## Managing Updates

### Approving PRs

1. **Review the changes**:
   - Check the changelog/release notes
   - Verify compatibility
   - Look for breaking changes

2. **Test locally** (if needed):
   ```bash
   git fetch origin
   git checkout renovate/docker-hashicorp-vault-1.x
   make vault-up
   # Test the changes
   ```

3. **Merge**:
   - Use GitHub UI or CLI
   - Renovate PRs follow conventional commits
   - Merging triggers automatic release

### Ignoring Dependencies

To ignore a dependency permanently, add to `renovate.json`:

```json
{
  "ignoreDeps": ["hashicorp/vault"]
}
```

Or ignore specific versions:

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["hashicorp/vault"],
      "allowedVersions": "!/^2\\./"
    }
  ]
}
```

### Manual Trigger

Renovate can be triggered manually:
1. Go to the Dependency Dashboard issue
2. Check the box next to the update you want
3. Renovate will create a PR within hours

## Customization

### Common Tweaks

**Change schedule**:
```json
{
  "schedule": ["every weekend"]
}
```

**Increase stability days** (more conservative):
```json
{
  "stabilityDays": 7
}
```

**Enable automerge** (not recommended):
```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true
    }
  ]
}
```

## Troubleshooting

### Renovate Not Creating PRs

1. Check the **Dependency Dashboard** for errors
2. Validate config: Run workflow `.github/workflows/renovate-validate.yml`
3. Check Renovate logs in the dashboard issue

### Too Many PRs

Adjust in `renovate.json`:
```json
{
  "prConcurrentLimit": 2,
  "prHourlyLimit": 1
}
```

### PRs Not Following Schedule

- Renovate may run outside schedule for security updates
- Dashboard can trigger immediate updates
- First run after enabling Renovate ignores schedule

## Best Practices

1. **Review major updates carefully** - Breaking changes likely
2. **Merge security updates quickly** - Tagged with `security`
3. **Use the dashboard** - Shows all pending updates
4. **Don't ignore too many dependencies** - Defeats the purpose
5. **Test breaking changes locally** - Before merging
6. **Keep Renovate config simple** - Easier to maintain

## Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Dependency Dashboard](https://docs.renovatebot.com/key-concepts/dashboard/)

## Getting Help

- Check the [Dependency Dashboard](../../issues) issue
- Review [Renovate logs](https://app.renovatebot.com/) (if using Renovate app)
- Open an issue in this repository
