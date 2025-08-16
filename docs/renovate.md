# Renovate Setup Instructions

This repository uses Renovate to automatically update dependencies via GitHub Actions using the built-in `GITHUB_TOKEN` with enhanced permissions.

## Setup Steps

### 1. Enable Enhanced Permissions (Already Configured)

The GitHub Action workflow is already configured with the necessary permissions:

- ✅ `contents: write` - To create commits and branches
- ✅ `pull-requests: write` - To create and update PRs
- ✅ `issues: write` - To create dependency dashboard
- ✅ `repository-projects: write` - To manage project boards
- ✅ `actions: read` - To read workflow information
- ✅ `checks: read` - To read check status
- ✅ `statuses: read` - To read commit status

### 2. No Additional Setup Required! 🎉

Unlike using a Personal Access Token, the built-in `GITHUB_TOKEN` requires no additional setup:

- ❌ No need to create a Personal Access Token
- ❌ No need to add repository secrets
- ❌ No need to manage token expiration
- ✅ Works automatically with enhanced permissions

### 3. Verify Setup

The GitHub Action will run:

- **Automatically**: Every Monday at 6 AM UTC
- **Manually**: Via the Actions tab → "Renovate" workflow → "Run workflow"
- **On config changes**: When you update `renovate.json` or the workflow file

## Configuration

- **Main config**: `renovate.json`
- **GitHub Action**: `.github/workflows/renovate.yml`
- **Code owners**: `.github/CODEOWNERS`

## Features

- ✅ Automatic Helm chart updates
- ✅ Docker image updates
- ✅ Kubernetes manifest updates
- ✅ k3s version updates in Ansible files
- ✅ Dependency dashboard
- ✅ Auto-merge for patch updates
- ✅ Grouped updates by type
- ✅ Code owner reviews

## Monitoring

- Check the dependency dashboard issue in your repository
- Monitor the Actions tab for workflow runs
- Review PRs created by Renovate Bot

## Troubleshooting

If Renovate isn't working:

1. Check the Actions tab for failed workflow runs
2. Verify the workflow has the correct permissions
3. Check the renovate.json syntax
4. Look at the workflow logs for detailed error messages
5. Ensure your repository allows GitHub Actions to create PRs (Settings → Actions → General → Workflow permissions)
