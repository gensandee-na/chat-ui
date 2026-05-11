# playwright-chatui-automation

A background worker that automates [gensandee-na/chat-ui](https://github.com/gensandee-na/chat-ui) using Playwright for UI-level interaction and a direct OpenAI-compatible backend client for faster requests.

## Project Structure

```
playwright-chatui-automation/
├── src/
│   ├── index.ts           # Background worker loop
│   ├── chatui-driver.ts   # Playwright UI automation
│   ├── backend-client.ts  # Direct API client
│   └── types.ts           # Shared TypeScript types
├── .github/
│   ├── workflows/
│   │   ├── ci.yml               # Build on push/PR
│   │   └── scheduled-jobs.yml   # Runs every 30 minutes
│   └── PULLREQUESTTEMPLATE.md
├── package.json
├── tsconfig.json
└── .gitignore
```

## Prerequisites

- Node.js 20+
- A running [chat-ui](https://github.com/gensandee-na/chat-ui) instance on `http://localhost:3000`
- An OpenAI-compatible backend on `http://localhost:11434` (e.g. Ollama)

## Setup

```bash
npm install
npx playwright install chromium
```

## Usage

```bash
# Build
npm run build

# Run the worker
npm start
```

The worker sends a message through the chat-ui every 30 seconds, logging both the UI reply and the backend API reply. It handles `SIGINT`/`SIGTERM` for clean shutdown.

## Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new automation worker
fix: correct backend client error handling
chore: update dependencies
docs: improve README
refactor: optimize worker loop
```
