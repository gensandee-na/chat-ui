# Contributing to chat-ui (SakThai)

Thanks for your interest in contributing! This is a fork of [huggingface/chat-ui](https://github.com/huggingface/chat-ui).

## Getting Started

1. Fork the repo and clone it locally
2. Check out the `SakThai` branch
3. Install dependencies: `npm install`
4. Copy `.env` to `.env.local` and configure your API key
5. Run the dev server: `npm run dev`

## Branch Strategy

| Branch | Purpose |
|---|---|
| `SakThai` | Active development (default) |
| `main` | Stable releases |
| `legacy` | Old version (upstream) |

## Making Changes

- Create a feature branch from `SakThai`: `git checkout -b feature/your-feature`
- Follow the [code conventions](README.md#development) — Svelte 5 runes, TypeScript strict
- Run `npm run check && npm run lint` before committing
- Write or update tests where applicable
- Open a Pull Request targeting `SakThai`

## Commit Style

Use conventional commits:

```
feat: add MCP server health check UI
fix: resolve SSE streaming disconnect on slow networks
docs: update env-vars reference for LLM router
chore: bump SvelteKit to 2.x
```

## Reporting Issues

Open a GitHub Issue with:
- Steps to reproduce
- Expected vs actual behavior
- Node version, OS, and relevant env config (no secrets!)

## Upstream Sync

This fork tracks [huggingface/chat-ui](https://github.com/huggingface/chat-ui). To pull upstream changes:

```bash
git remote add upstream https://github.com/huggingface/chat-ui.git
git fetch upstream
git merge upstream/main
```
