# Gemini Project Instructions: Chat-UI Automation

This file contains team-shared instructions for the `chat-ui` project's automation and LLM integration.

## Automation Workflow
We use a custom Playwright-based agent for E2E testing and UI automation.
- **Entry Point**: `npm run agent "<task>"`
- **Architecture**: The agent follows an iterative **Observe-Reason-Act** loop.
- **Selectors**: Prioritize user-visible locators (ARIA roles, accessible names). See `hf-chatui-agent/references/playwright-best-practices.md`.
- **Coordinates**: The agent supports 0-999 normalized coordinates for visual targeting.

## LLM Integration
- **Default Provider**: Hugging Face Router (`https://router.huggingface.co/v1`).
- **Configuration**: Managed via `.env` (copy from `.env.example`).
- **Models**: Preferred models include `meta-llama/Llama-3.3-70B-Instruct`.

## Development Standards
- **Environment**: Automation scripts (`hf-action-agent.ts`, etc.) are isolated in `tsconfig.json` to prevent SvelteKit build conflicts.
- **Verification**: New UI features should be verified using the agent or standard Playwright tests in the `tests/` directory.
