# Create src directory if it doesn't exist
if (-Not (Test-Path "src")) {
    New-Item -ItemType Directory -Force -Path "src" | Out-Null
}

# Move typescript files to src
$tsFiles = @("index.ts", "chatui-driver.ts", "backend-client.ts", "types.ts")
foreach ($ts in $tsFiles) {
    if (Test-Path $ts) {
        Move-Item -Path $ts -Destination "src\" -Force
    }
}

# Create .github\workflows if it doesn't exist
if (-Not (Test-Path ".github\workflows")) {
    New-Item -ItemType Directory -Force -Path ".github\workflows" | Out-Null
} else {
    # Empty the workflows directory of old stuff
    Get-ChildItem -Path ".github\workflows" -File | Remove-Item -Force
}

# Move workflow files
$wfFiles = @("ci.yml", "scheduled-jobs.yml")
foreach ($wf in $wfFiles) {
    if (Test-Path $wf) {
        Move-Item -Path $wf -Destination ".github\workflows\" -Force
    }
}

# Move pull request template
if (Test-Path "PULLREQUESTTEMPLATE.md") {
    Move-Item -Path "PULLREQUESTTEMPLATE.md" -Destination ".github\" -Force
}

# Delete outdated files
$filesToDelete = @(
    ".eslintignore", ".eslintrc.cjs", ".prettierignore", ".prettierrc",
    "Dockerfile", "docker-compose.yml", "entrypoint.sh",
    "postcss.config.js", "svelte.config.js", "tailwind.config.cjs", "vite.config.ts",
    "server.log", "setup-github.sh", "CLA.md", "CLAUDE.md", "LICENSE.md", "PRIVACY.md", "SECURITY.md",
    ".env", ".env.ci"
)

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
    }
}

# Delete outdated directories
$dirsToDelete = @(
    "chart", "codeql-custom-queries-actions", "docs", "models", "scripts", "static", "stub", ".devcontainer", ".claude"
)

foreach ($dir in $dirsToDelete) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Delete other .github stuff that is not workflows or PULLREQUESTTEMPLATE.md
if (Test-Path ".github\ISSUE_TEMPLATE") { Remove-Item -Path ".github\ISSUE_TEMPLATE" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path ".github\dependabot.yml") { Remove-Item -Path ".github\dependabot.yml" -Force -ErrorAction SilentlyContinue }
if (Test-Path ".github\release.yml") { Remove-Item -Path ".github\release.yml" -Force -ErrorAction SilentlyContinue }

# Run npm install
Write-Host "Running npm install..."
npm install

# Run build to verify setup
Write-Host "Running npm run build..."
npm run build

Write-Host "Cleanup and setup complete."
