# Hugging Face Action Agent for Chat-UI

This agent uses Hugging Face models (via the HF Router) to automate browser tasks using Playwright.

## Prerequisites

1.  **Hugging Face Token**: Set your `HF_TOKEN` or `OPENAI_API_KEY` in your environment.
    ```powershell
    $env:OPENAI_API_KEY = "hf_..."
    ```
2.  **Dependencies**: Already installed via `npm install`.
3.  **Playwright Browsers**: Already installed via `npx playwright install`.

## Running the Agent

You can run the agent with a natural language task:

```bash
npm run agent "Go to http://localhost:5173, click the 'New Chat' button, and type 'Hello world' in the textarea"
```

## How it works

1.  **Backend Client**: `backend-client.ts` calls the Hugging Face Router (`https://router.huggingface.co/v1`).
2.  **Action Agent**: `hf-action-agent.ts` sends your task to the LLM and asks for a JSON sequence of Playwright actions.
3.  **Execution**: The agent executes the actions one by one using Playwright.

## Customization

- **Model**: Change `MODEL` in `backend-client.ts` (default is `meta-llama/Llama-3.3-70B-Instruct`).
- **Base URL**: Change `BASE_URL` in `backend-client.ts` to use a different OpenAI-compatible provider.
