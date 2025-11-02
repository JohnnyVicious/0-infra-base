# Setting Up Renovate Bot

This guide will help you enable Renovate Bot for this repository.

## Quick Setup (Recommended)

### Option 1: GitHub App (Easiest)

1. **Install the Renovate GitHub App**:
   - Go to https://github.com/apps/renovate
   - Click "Install" or "Configure"
   - Select your account/organization
   - Choose "Only select repositories"
   - Select this repository (`0-infra-base`)
   - Click "Install"

2. **Done!** Renovate will:
   - Detect the `renovate.json` config automatically
   - Create a "Configure Renovate" onboarding PR
   - Start scanning for updates weekly

### Option 2: Self-Hosted Renovate (GitHub Action)

If you prefer to run Renovate under your own credentials (instead of the hosted Renovate App):

1. **Create a GitHub Personal Access Token**:
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Scopes needed:
     - `repo` (Full control of private repositories)
     - `workflow` (Update GitHub Action workflows)
   - Copy the token

2. **Store token in Vault**:
   ```bash
   docker exec -it vault vault kv put github/renovate token=ghp_your_token_here
   ```

3. **Workflow**: This repository already ships with a scheduled workflow at `.github/workflows/renovate-run.yml`. It triggers nightly at **03:00 UTC** and can be dispatched manually. Update the cron if you need a different cadence or add additional env vars (e.g., `RENOVATE_AUTODISCOVER`).

4. **Add secret to GitHub**:
   - Go to repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `RENOVATE_TOKEN`
   - Value: Your GitHub token (or read from Vault in workflow)

## What Happens Next

### First Run (Onboarding)

Renovate will create a PR titled **"Configure Renovate"**:
- Reviews your `renovate.json` config
- Lists all detected dependencies
- No changes are made yet
- Merge this PR to activate Renovate

### After Onboarding

1. **Dependency Dashboard** issue is created
2. **Nightly scans** (03:00 UTC via GitHub Action)
3. **PRs created** for outdated dependencies
4. **Security alerts** trigger immediate PRs

## First Steps After Setup

### 1. Merge Onboarding PR

Review and merge the "Configure Renovate" PR.

### 2. Check Dependency Dashboard

Go to Issues → Look for "Renovate Dashboard"
- See all pending updates
- Manually trigger updates
- View configuration errors

### 3. Review First Updates

Renovate will create PRs for:
- Outdated Docker images
- Old Terraform providers
- Outdated GitHub Actions

Review and merge these PRs.

### 4. Sync Labels

Run the label sync workflow to create Renovate labels:
```bash
# Trigger via GitHub Actions UI
# Or push to main to trigger automatically
```

## Configuration

Your repository already has `renovate.json` configured with:
- Nightly schedule (03:00 UTC) enforced by the GitHub Action
- Conventional commit format
- Grouped updates (Terraform, GitHub Actions)
- Security vulnerability alerts
- Digest pinning for Docker/Actions

To customize, edit [renovate.json](../renovate.json).

## Testing Renovate

### Validate Configuration

Check if your config is valid:
```bash
npm install -g renovate
renovate-config-validator
```

Or use the GitHub Actions workflow:
- Go to Actions → "Renovate Config Validation"
- Click "Run workflow"

### Trigger Manual Run

**GitHub App**:
- Go to Dependency Dashboard issue
- Check boxes next to updates you want
- Renovate runs within hours

**Self-hosted**:
- Go to Actions → "Renovate Nightly"
- Click "Run workflow"

## Troubleshooting

### No PRs Created

**Check**:
1. Onboarding PR merged?
2. Dependencies actually outdated?
3. Configuration valid? (Run validation workflow)
4. Rate limits hit? (Check Dependency Dashboard)

**Solution**:
- Review Dependency Dashboard for errors
- Check Renovate logs (GitHub App dashboard)
- Manually trigger a run

### Too Many PRs

**Reduce concurrent PRs** in `renovate.json`:
```json
{
  "prConcurrentLimit": 2
}
```

### PRs Not Following Conventional Commits

**Check** `renovate.json` has:
```json
{
  "semanticCommits": "enabled",
  "commitMessagePrefix": "chore(deps):"
}
```

### Renovate Not Using Schedule

- First run ignores schedule
- Security updates ignore schedule
- Manual triggers ignore schedule

## Advanced Configuration

### Automerge (Use Carefully)

Enable automerge for patch updates:
```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true,
      "automergeType": "pr"
    }
  ]
}
```

### Custom Schedules per Dependency

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["hashicorp/vault"],
      "schedule": ["every weekend"]
    }
  ]
}
```

### Notifications

Get notified of Renovate PRs:
```json
{
  "assignees": ["your-github-username"],
  "reviewers": ["your-github-username"]
}
```

## Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Renovate Configuration](https://docs.renovatebot.com/configuration-options/)
- [GitHub App Dashboard](https://app.renovatebot.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)

## Next Steps

1. ✅ Install Renovate (GitHub App or self-hosted)
2. ✅ Merge onboarding PR
3. ✅ Review Dependency Dashboard
4. ✅ Merge first update PRs
5. ✅ Customize `renovate.json` if needed

Happy automating!
