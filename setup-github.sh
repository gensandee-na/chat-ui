#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# setup-github.sh
# Run this once inside the playwright-chatui-automation folder
# to create a GitHub repo and push all files.
#
# Requirements:
#   - git installed
#   - GitHub CLI (gh) installed → https://cli.github.com
#
# Usage:
#   chmod +x setup-github.sh
#   ./setup-github.sh
# ─────────────────────────────────────────────────────────────

set -e

REPO_NAME="playwright-chatui-automation"
DESCRIPTION="Playwright + Chat-UI background worker automation"

echo "🔐 Checking GitHub CLI auth..."
if ! gh auth status &>/dev/null; then
  echo "Not logged in. Running: gh auth login"
  gh auth login
fi

echo "📁 Initialising git repo..."
git init
git add .
git commit -m "feat: initial commit — full Playwright + Chat-UI automation system"

echo "🚀 Creating GitHub repo and pushing..."
gh repo create "$REPO_NAME" \
  --public \
  --description "$DESCRIPTION" \
  --source=. \
  --remote=origin \
  --push

echo ""
echo "✅ Done! Your repo is live at:"
gh repo view --json url -q .url
