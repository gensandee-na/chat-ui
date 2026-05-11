# Chat UI — SakThai Fork

![Chat UI](https://huggingface.co/datasets/huggingface/documentation-images/resolve/main/chat-ui/chat-ui-2026.png)

> A SvelteKit chat interface for LLMs — forked from [huggingface/chat-ui](https://github.com/huggingface/chat-ui), powering [HuggingChat on hf.co/chat](https://huggingface.co/chat).  
> Branch: **SakThai** · Maintained by [@gensandee-na](https://github.com/gensandee-na)

[![HuggingChat](https://img.shields.io/badge/HuggingChat-hf.co%2Fchat-yellow?logo=huggingface)](https://huggingface.co/chat)
[![SvelteKit](https://img.shields.io/badge/SvelteKit-2.x-orange?logo=svelte)](https://kit.svelte.dev)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

---

## Table of Contents

1. [Overview](#overview)
2. [Quickstart](#quickstart)
3. [Database Options](#database-options)
4. [Launch](#launch)
5. [Docker](#docker)
6. [Configuration](#configuration)
7. [LLM Router](#llm-router)
8. [MCP Tools](#mcp-tools)
9. [Architecture](#architecture)
10. [Development](#development)
11. [Testing](#testing)
12. [Building & Deploying](#building--deploying)

---

## Overview

**Chat UI** is a full-featured, self-hostable chat interface for large language models. It powers [HuggingChat](https://huggingface.co/chat) — Hugging Face's flagship conversational AI app.

> **Note:** Chat UI only supports OpenAI-compatible APIs via `OPENAI_BASE_URL` and the `/models` endpoint. Any service that speaks the OpenAI protocol works — llama.cpp server, Ollama, OpenRouter, and more. Provider-specific integrations (legacy `MODELS` env var, GGUF discovery, embeddings, web-search helpers) are removed in the current version.

> The old version is still available on the [legacy branch](https://github.com/huggingface/chat-ui/tree/legacy).

---

## Quickstart

Chat UI talks to OpenAI-compatible APIs only. The fastest way to get running is via the **Hugging Face Inference Providers router** and your personal HF access token.

**Step 1 — Create `.env.local`:**

```env
OPENAI_BASE_URL=https://router.huggingface.co/v1
OPENAI_API_KEY=hf_************************
```

| Provider | `OPENAI_BASE_URL` | API Key |
|---|---|---|
| **HF Inference Providers** (recommended) | `https://router.huggingface.co/v1` | `hf_xxx` (or `HF_TOKEN`) |
| llama.cpp server | `http://127.0.0.1:8080/v1` | any string |
| Ollama | `http://127.0.0.1:11434/v1` | `ollama` |
| OpenRouter | `https://openrouter.ai/api/v1` | `sk-or-v1-...` |
| Poe | `https://api.poe.com/v1` | `pk_...` |

See the root [`.env` template](./.env) for the full list of optional variables.

**Step 2 — Install and run:**

```bash
git clone https://github.com/gensandee-na/chat-ui.git
cd chat-ui
git checkout SakThai
npm install
npm run dev -- --open
```

Open your browser and start chatting at `http://localhost:5173`.

---

## Database Options

Chat history, users, settings, files, and stats all live in MongoDB.

> **Tip:** For local development, skip this section. When `MONGODB_URL` is not set, Chat UI falls back to an embedded database persisted at `./db`.

### MongoDB Atlas (managed)

1. Create a free cluster at [mongodb.com](https://www.mongodb.com/pricing)
2. Add your IP to the network access list
3. Create a database user and copy the connection string
4. Set `MONGODB_URL` in `.env.local`

### Local MongoDB (Docker)

```bash
docker run -d -p 27017:27017 --name mongo-chatui mongo:latest
```

```env
MONGODB_URL=mongodb://localhost:27017
MONGODB_DB_NAME=chat-ui
```

---

## Launch

```bash
npm install
npm run dev        # → http://localhost:5173
```

For production:

```bash
npm run build
npm run preview
```

---

## Docker

The `chat-ui-db` image bundles MongoDB inside the container — no separate DB needed:

```bash
docker run \
  -p 3000:3000 \
  -e OPENAI_BASE_URL=https://router.huggingface.co/v1 \
  -e OPENAI_API_KEY=hf_*** \
  -v chat-ui-data:/data \
  ghcr.io/huggingface/chat-ui-db:latest
```

All `.env.local` variables can be passed as `-e` flags.

---

## Configuration

### Theming

```env
PUBLIC_APP_NAME=ChatUI
PUBLIC_APP_ASSETS=chatui           # "chatui" or "huggingchat"
PUBLIC_APP_DESCRIPTION="Making the community's best AI chat models available to everyone."
PUBLIC_APP_DATA_SHARING=           # set to "1" to enable opt-in data sharing toggle
```

### Models

Models are auto-discovered from `${OPENAI_BASE_URL}/models`. You can optionally override metadata via the `MODELS` env var (JSON5). Authorization uses `OPENAI_API_KEY` (`HF_TOKEN` is a legacy alias).

---

## LLM Router

Chat UI supports server-side smart routing via [katanemo/Arch-Router-1.5B](https://huggingface.co/katanemo/Arch-Router-1.5B). The UI exposes a virtual **"Omni"** model alias that picks the best route per message.

```env
LLM_ROUTER_ROUTES_PATH=config/routes.chat.json    # your routes JSON
LLM_ROUTER_ARCH_BASE_URL=...                       # OpenAI-compat router endpoint
LLM_ROUTER_ARCH_MODEL=router/omni
LLM_ROUTER_OTHER_ROUTE=casual_conversation
LLM_ROUTER_FALLBACK_MODEL=<model-id>
LLM_ROUTER_ARCH_TIMEOUT_MS=10000

# Omni alias display
PUBLIC_LLM_ROUTER_ALIAS_ID=omni
PUBLIC_LLM_ROUTER_DISPLAY_NAME=Omni
PUBLIC_LLM_ROUTER_LOGO_URL=

# Shortcuts
LLM_ROUTER_ENABLE_MULTIMODAL=true
LLM_ROUTER_MULTIMODAL_MODEL=<model-id>
LLM_ROUTER_ENABLE_TOOLS=true
LLM_ROUTER_TOOLS_MODEL=<model-id>
```

When **Omni** is selected, Chat UI:
1. Calls the Arch endpoint (non-streaming) to pick the best route
2. Emits `RouterMetadata` (route + model used) to the UI
3. Streams from the selected model via `OPENAI_BASE_URL`
4. Falls back through configured fallback models on errors

---

## MCP Tools

Chat UI supports [Model Context Protocol (MCP)](https://modelcontextprotocol.io) servers — tools exposed as OpenAI function calls, results fed back to the model.

```env
MCP_SERVERS=[
  {"name": "Web Search (Exa)", "url": "https://mcp.exa.ai/mcp"},
  {"name": "Hugging Face MCP Login", "url": "https://hf.co/mcp?login"}
]

# Forward the signed-in user's HF token to official HF MCP endpoints
MCP_FORWARD_HF_USER_TOKEN=true
```

**Using tools in the UI:**
- Open **MCP Servers** from the top-right menu or the `+` button in chat input
- Add servers, toggle them on, run Health Check
- When a model calls a tool: parameters → progress bar → result (or error)

**Per-model overrides:**  
In Settings → Model, toggle "Tool calling (functions)" and "Multimodal input" per model — even if provider metadata doesn't advertise these capabilities.

---

## Architecture

### SvelteKit App (`src/`)

```
src/
├── lib/
│   ├── components/
│   │   ├── chat/           # ChatWindow, ChatInput, ChatMessage, MarkdownRenderer
│   │   ├── mcp/            # MCP server manager UI
│   │   └── icons/          # Custom SVG icons
│   ├── server/
│   │   ├── textGeneration/ # LLM streaming pipeline (generate.ts, mcp/, reasoning.ts)
│   │   ├── mcp/            # MCP client pool & tool invocation
│   │   ├── router/         # Smart model routing (Omni / Arch-Router)
│   │   ├── endpoints/      # OpenAI-compatible endpoint wrappers
│   │   ├── database.ts     # MongoDB collections
│   │   ├── models.ts       # Model registry from OPENAI_BASE_URL/models
│   │   └── auth.ts         # OIDC authentication
│   ├── types/              # TypeScript interfaces
│   ├── stores/             # Svelte reactive state
│   └── utils/              # Helpers
└── routes/
    ├── conversation/[id]/  # Main chat page + SSE streaming endpoint
    ├── settings/           # User settings
    ├── api/v2/             # REST API (conversations, models, user, MCP)
    └── models/             # Model browser pages
```

**Text generation flow:**
```
POST /conversation/[id]
  → auth + conversation history
  → message tree
  → LLM endpoint (OpenAI-compat client)
  → SSE stream
  → MongoDB
```

### Playwright Automation Worker

| File | Role |
|---|---|
| `index.ts` | Main loop — launches Chromium, calls `runJob()` every 30 s |
| `chatui-driver.ts` | `sendMessageThroughUI(page, msg)` — fills textarea, clicks Send |
| `backend-client.ts` | `callChatBackend(prompt)` — POSTs to `:11434/v1/chat/completions` |
| `types.ts` | `JobResult`, `ChatCompletionResponse` interfaces |

---

## Development

```bash
npm run dev       # Dev server → http://localhost:5173
npm run build     # Production build
npm run check     # TypeScript + Svelte validation
npm run lint      # Prettier + ESLint check
npm run format    # Auto-format
npm run test      # Vitest (all workspaces)
```

### Code Conventions

- **Svelte 5 runes** — `$state()`, `$effect()`, `$bindable()` — no legacy `$:` syntax
- **TypeScript strict** — no `any`, no non-null assertions (ESLint enforced)
- **Server/client separation** — never import `$lib/server/*` in client code
- **Prettier** — tabs, 100-char line width, Tailwind class sorting via plugin
- **Icons** — Carbon (`~icons/carbon/*`) or Lucide (`~icons/lucide/*`); custom in `$lib/components/icons/`

| Task | Where |
|---|---|
| Add a Svelte component | `src/lib/components/` — use Svelte 5 runes |
| Add an API route | `src/routes/api/v2/<name>/+server.ts` |
| Add a model route | JSON at `LLM_ROUTER_ROUTES_PATH` |
| Extend Playwright worker | `chatui-driver.ts` + `types.ts` + `npm run build` |
| Add user settings | `src/lib/types/Settings.ts` + settings API route |

---

## Testing

```bash
npm run test                              # All test workspaces
npx vitest run path/to/file.spec.ts      # Single file
```

| Pattern | Environment |
|---|---|
| `*.svelte.test.ts` | Browser (Playwright) |
| `*.ssr.test.ts` | Node SSR |
| `*.test.ts` / `*.spec.ts` | Node |

---

## Building & Deploying

```bash
npm run build
npm run preview    # Preview production build locally
```

Install a [SvelteKit adapter](https://kit.svelte.dev/docs/adapters) for your deployment target (Node, Vercel, Cloudflare, etc.).

---

## References

- [`references/env-vars.md`](references/env-vars.md) — Full environment variable reference
- [`references/ci.md`](references/ci.md) — GitHub Actions CI/CD workflows
- [HuggingChat](https://huggingface.co/chat) — Live deployment powered by this codebase
- [Official docs](https://huggingface.co/docs/chat-ui) — Hugging Face Chat UI documentation
- [Original repo](https://github.com/huggingface/chat-ui) — huggingface/chat-ui upstream

---

## License

Forked from [huggingface/chat-ui](https://github.com/huggingface/chat-ui) — Apache 2.0 License.
