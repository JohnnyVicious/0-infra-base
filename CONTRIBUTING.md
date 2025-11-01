# Contributing Guide

Thank you for contributing to 0-infra-base! This guide will help you understand our workflow and conventions.

## Conventional Commits

We use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages and PR titles. This enables automated semantic versioning.

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | New feature | Minor (0.x.0) |
| `fix` | Bug fix | Patch (0.0.x) |
| `perf` | Performance improvement | Patch (0.0.x) |
| `docs` | Documentation changes | Patch (0.0.x) |
| `style` | Code style changes | Patch (0.0.x) |
| `refactor` | Code refactoring | Patch (0.0.x) |
| `test` | Test updates | Patch (0.0.x) |
| `build` | Build system changes | Patch (0.0.x) |
| `ci` | CI/CD changes | Patch (0.0.x) |
| `chore` | Other changes | None |
| `revert` | Reverts a previous commit | Patch (0.0.x) |

### Breaking Changes

Breaking changes trigger a **major version bump** (x.0.0). Indicate breaking changes by:

1. Adding `!` after the type: `feat!: new API structure`
2. Adding `BREAKING CHANGE:` in the footer:
   ```
   feat: new authentication system

   BREAKING CHANGE: the old auth tokens are no longer supported
   ```

### Examples

```bash
# Feature (minor bump)
feat: add vault auto-unseal support

# Bug fix (patch bump)
fix(terraform): resolve repository creation timeout

# Documentation (patch bump)
docs: update bootstrap guide with troubleshooting

# Breaking change (major bump)
feat!: migrate to terraform 1.8

BREAKING CHANGE: requires terraform >= 1.8.0
```

## Pull Request Workflow

### 1. Create a Branch

```bash
git checkout -b feat/your-feature-name
# or
git checkout -b fix/bug-description
```

### 2. Make Your Changes

- Follow existing code style
- Update documentation if needed
- Test your changes locally

### 3. Commit with Conventional Commits

```bash
git commit -m "feat: add new repository template"
```

### 4. Push and Create PR

```bash
git push origin feat/your-feature-name
```

**Important:** Your PR title must follow conventional commit format. The PR title is used for the release notes, not individual commits.

### 5. PR Title Format

✅ Good PR titles:
- `feat: add docker-compose for vault`
- `fix(ci): resolve release workflow permissions`
- `docs: add contributing guide`
- `feat!: upgrade to vault 1.15`

❌ Bad PR titles:
- `Update files`
- `Fix bug`
- `WIP changes`

### 6. Automated Labels

When you create a PR, a GitHub Action will automatically label it based on the title:
- `semver:major` - Breaking changes (x.0.0)
- `semver:minor` - New features (0.x.0)
- `semver:patch` - Fixes and improvements (0.0.x)
- `semver:none` - No version bump (chore, etc.)

### 7. Merge to Main

Once approved and merged, the release workflow automatically:
1. Analyzes commits since last release
2. Determines the next version number
3. Generates release notes
4. Creates a GitHub release
5. Updates CHANGELOG.md
6. Tags the release

## Release Process

Releases are **fully automated**. When a PR is merged to main:

1. **semantic-release** analyzes the PR title
2. Determines version bump based on type
3. Creates a new release with:
   - Version tag (e.g., v1.2.3)
   - Release notes categorized by type
   - Updated CHANGELOG.md

### Version Numbers

We follow [Semantic Versioning](https://semver.org/):

- **Major (x.0.0)**: Breaking changes
- **Minor (0.x.0)**: New features (backwards compatible)
- **Patch (0.0.x)**: Bug fixes and improvements

### Release Notes

Release notes are automatically generated and grouped by category:

```markdown
## Features
- feat: add vault auto-unseal support

## Bug Fixes
- fix(terraform): resolve timeout issue

## Documentation
- docs: update bootstrap guide
```

## Local Development

### Prerequisites

- Docker and Docker Compose
- Terraform >= 1.0
- Git

### Setup

1. Start Vault:
   ```bash
   make vault-up
   ```

2. Configure Vault:
   ```bash
   make vault-setup
   ```

3. Initialize Terraform:
   ```bash
   make terraform-init
   ```

### Testing Changes

Before submitting a PR:

1. Test Vault changes:
   ```bash
   docker-compose down
   docker-compose up -d
   make vault-status
   ```

2. Test Terraform changes:
   ```bash
   cd terraform
   terraform validate
   terraform plan
   ```

3. Verify documentation is up to date

## Questions or Issues?

- Open an issue for bugs or feature requests
- Use GitHub Discussions for questions
- Check [BOOTSTRAP.md](BOOTSTRAP.md) for setup help

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow

Thank you for contributing!
