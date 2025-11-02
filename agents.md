# Automation Agents

This document catalogues the automated agents that keep `0-infra-base` healthy. Use it as a quick reference when you need to understand what is running, why it runs, and where to adjust behaviour.

## Summary

| Agent | Type | Trigger(s) | Responsibilities | Configuration |
|-------|------|------------|------------------|---------------|
| Release workflow | GitHub Action | Push to `main` | Runs `semantic-release` to cut versions, publish GitHub releases, and open a `CHANGELOG.md` PR | `.github/workflows/release.yml`, `.releaserc.json` |
| PR Labeler | GitHub Action | PR opened/edited/synced/reopened | Applies the correct `semver:*` label based on the PR title's conventional commit prefix | `.github/workflows/pr-labeler.yml`, `.github/labels.yml` |
| Label Sync | GitHub Action | Push to `main` touching `.github/labels.yml`, manual dispatch | Reconciles repository labels with the manifest without pruning unknown labels | `.github/workflows/label-sync.yml`, `.github/labels.yml` |
| Renovate config validator | GitHub Action | PR or push touching `renovate.json` or the workflow itself | Verifies that the Renovate configuration stays valid before merging | `.github/workflows/renovate-validate.yml`, `renovate.json` |
| Renovate nightly run | GitHub Action | Daily cron (03:00 UTC), manual dispatch | Executes Renovate self-hosted action to ensure dependency checks run even if the hosted app is idle | `.github/workflows/renovate-run.yml`, `renovate.json`, `secrets.RENOVATE_TOKEN` |
| CodeQL security scan | GitHub Action | Push/PR to `main`, weekly cron (Mon 06:00 UTC), manual dispatch | Runs GitHub CodeQL against the repository's GitHub Actions code and uploads SARIF results | `.github/workflows/codeql.yml`, `.github/codeql/codeql-config.yml` |
| Renovate Bot | Hosted service | Weekly schedule (Mondays), manual dashboard | Opens dependency update PRs with conventional commit titles and curated labels | `renovate.json`, `.github/renovate.md`, `.github/RENOVATE_SETUP.md` |

## GitHub Action Agents

### Release workflow
- **Purpose:** Automates semantic versioning using [`semantic-release`](https://semantic-release.gitbook.io/semantic-release/).
- **Secrets:** Uses `GITHUB_TOKEN` for release publishing and a dedicated `RELEASE_PR_TOKEN` (PAT with `repo` scope) to open the changelog PR because repository rules block Actions-owned pull requests.
- **Key behaviour:** Fetches full history (`fetch-depth: 0`) so semantic-release can inspect tags. After publishing, it raises a PR with the generated `CHANGELOG.md` entry instead of pushing directly to `main`.
- **Where to customise:** Edit `.releaserc.json` to adjust release plugins or changelog sections. Tweak `.github/workflows/release.yml` if you want to label or auto-merge the changelog PR.

### PR Labeler
- **Purpose:** Keeps PRs aligned with the release process by assigning one of the `semver:*` labels based on the title.
- **Trigger notes:** Runs on every PR title change, sync, and reopen to ensure the label reflects the latest title.
- **Conflict handling:** Removes a previous `semver:*` label before applying a new one to avoid drift.
- **Where to customise:** Update the label mapping logic inside `.github/workflows/pr-labeler.yml` if you introduce new commit prefixes or label categories.

### Label Sync
- **Purpose:** Ensures repository labels stay in sync with the manifest stored in `.github/labels.yml`.
- **Behaviour:** Uses `micnncim/action-label-syncer@v1` with `prune: false`, so labels absent from the manifest are preserved. This is helpful when downstream automation (for example, Renovate) injects temporary labels.
- **Operational tips:** After editing `.github/labels.yml`, push to `main` or trigger the workflow manually via the Actions tab to apply changes.

### Renovate config validator
- **Purpose:** Protects the Renovate Bot from breaking changes by validating `renovate.json` inside CI before merge.
- **Implementation:** Installs the official Renovate CLI (`npm install -g renovate`) and runs `renovate-config-validator`.
- **Where to customise:** Modify `.github/workflows/renovate-validate.yml` if you need to pin a Renovate version or add additional sanity checks.

### Renovate nightly run
- **Purpose:** Forces a Renovate sweep at 03:00 UTC daily so dependency updates keep flowing even if the hosted Renovate App is throttled.
- **Secrets:** Requires `secrets.RENOVATE_TOKEN` (PAT with `repo`, `workflow`, and `read:org` if managing org repos). The default `GITHUB_TOKEN` cannot be used.
- **Configuration:** Respects `renovate.json`; adjust that file to tune package rules. Modify `.github/workflows/renovate-run.yml` to change schedule, logging, or extra env vars (e.g., `RENOVATE_AUTODISCOVER`).
- **Operational tips:** Monitor the workflow logs for rate-limit warnings. Rotate the PAT periodically and ensure it is scoped narrowly to the repositories Renovate must touch.
### CodeQL security scan
- **Purpose:** Provides ongoing security analysis for the repository's GitHub Actions and scripts.
- **Scope:** Currently configured to scan the `actions` language family via `.github/codeql/codeql-config.yml`. Extend the `languages` list if you add compiled code (Go, C#, etc.).
- **Runtime:** Uses the default autobuild step, which is a no-op for scripting languages but harmless if additional languages are added later.
- **Results:** Findings appear in the repository's **Security → Code scanning alerts** dashboard and in PR checks. Resolve or triage alerts directly from those views.

## Renovate Bot

- **Hosting:** Runs as the hosted Renovate GitHub App; no infrastructure is required in this repository.
- **Schedule:** Weekly runs (Monday mornings) plus the Renovate Dependency Dashboard for manual retries or force runs.
- **Outputs:** Creates PRs with conventional commit titles (`chore(deps)`, `feat(deps)`, `fix(security)`) so releases remain automated.
- **Label strategy:** Applies labels such as `dependencies`, `automerge-candidate`, or `major-update` according to the rules defined in `renovate.json`.
- **Customisation:** Adjust the presets and package rules in `renovate.json`, and refer to `.github/renovate.md` or `.github/RENOVATE_SETUP.md` for integration guidance and onboarding steps.
- **Operational tips:** Renovate PRs may require manual approval when major updates or breaking changes are detected. Use the Dependency Dashboard issue to see pending updates and retry failed jobs.

## Keeping Agents Healthy

- Monitor the **Actions** tab for failing workflows and the **Security** tab for CodeQL alerts.
- Ensure `GITHUB_TOKEN` retains appropriate permissions if repository settings change; several workflows write back to the repo.
- Review Renovate PRs promptly to avoid dependency drift and reduce the number of simultaneous update branches.
- When modifying automation, update this document so everyone understands the current agent landscape.
