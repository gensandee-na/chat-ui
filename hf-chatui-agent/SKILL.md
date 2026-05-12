---
name: hf-chatui-agent
description: Automate browser tasks for the chat-ui application using Hugging Face models and Playwright. Use when you need to perform end-to-end tests, verify UI components, or simulate user interactions in chat-ui.
---

# HF Chat-UI Agent Skill

This skill provides a framework for automating tasks in the `chat-ui` application using Hugging Face models (via the HF Router) and Playwright.

## Core Workflow

1.  **Define Task**: Start with a natural language description.
2.  **Run Agent**: Execute the agent using `npm run agent "<task>"`.
3.  **Iterative Execution**: The agent now operates in an **Observe-Reason-Act** loop. It analyzes the current page, performs one action, and repeats until the task is marked as "done".
4.  **Coordinate Support**: The agent can now use a **0-999 normalized grid** to interact with elements via `click_at` and `type_at`, in addition to traditional DOM selectors.

## Common Selectors for Chat-UI

When writing tasks or refining the agent, use these common selectors:

- **New Chat Button**: `button:has-text("New Chat")`
- **Chat Input (Textarea)**: `textarea[placeholder*="Ask"]` or simply `textarea`
- **Send Button**: `button[type="submit"]`
- **Message Content**: `.message-content`
- **Settings Link**: `a[href="/settings"]`

## Scripts

- `scripts/run_agent.cjs`: A wrapper to run the agent with environment checks.

## References

- [selectors.md](references/selectors.md): Comprehensive list of selectors for various `chat-ui` themes and components.
- [tasks.md](references/tasks.md): Examples of common automation tasks and expected outcomes.
- [playwright-best-practices.md](references/playwright-best-practices.md): Guidelines for writing resilient selectors and avoiding strict mode violations.
- [gemini-computer-use-guidelines.md](references/gemini-computer-use-guidelines.md): Best practices for visual/coordinate-based UI automation and safety.

## Debugging

If the agent fails:
1. Check `debug.png` (if a `screenshot` action was included).
2. Verify that the `OPENAI_API_KEY` or `HF_TOKEN` is correctly set in `.env`.
3. Ensure the `chat-ui` server is running if testing local URLs.
