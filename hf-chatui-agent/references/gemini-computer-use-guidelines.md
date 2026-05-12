# Gemini Computer Use Guidelines

This reference summarizes key concepts and best practices for Gemini-based computer use and UI automation, based on the official Gemini API documentation.

## 1. The Agent Loop
Visual automation follows a recursive four-step loop:
1.  **Observe:** Capture the current environment state (screenshot and URL).
2.  **Reason:** Send the prompt and state to the model.
3.  **Act:** Execute the model's predicted function call (e.g., `click_at`, `type_text_at`).
4.  **Validate:** Observe the new state to confirm the action's success.

## 2. Coordinate Scaling
Gemini predicts UI interactions using a **normalized 0–999 coordinate grid** (1000x1000).
*   **Normalization:** To map a pixel to a Gemini coordinate: `(pixel / dimension) * 1000`.
*   **Denormalization:** To map a Gemini coordinate back to a pixel: `(coordinate / 1000) * dimension`.
*   **Recommended Resolution:** 1440x900 is the standard reference size for optimal model performance.

## 3. Best Practices
*   **Human-in-the-Loop (HITL):** Explicit confirmation is **mandatory** for irreversible or consequential actions (e.g., payments, sending emails, deleting data).
*   **Secure Sandboxing:** Automation should run in a dedicated, isolated environment (Docker or a separate browser profile) to prevent system damage or data leaks.
*   **Clean Starting State:** Always start tasks from a known, clean state to minimize interference from previous sessions or unexpected pop-ups.
*   **Handle "Instruction Injection":** Be aware that the model might follow instructions found on the webpage (e.g., a fake survey) instead of the user's intent.

## 5. Local Laptop Implementation
To connect Gemini Computer Use to your local laptop or environment, follow these technical requirements:

*   **Action Handler:** Use **Playwright** for browser-based tasks. For local visibility, launch the browser with `headless: false`.
    ```javascript
    const browser = await playwright.chromium.launch({ headless: false });
    ```
*   **Screen Capture:** Capture the state after every action using `page.screenshot({ type: 'png' })`. This screenshot must be sent back to the model as part of the next turn.
*   **Coordinate Denormalization:** Map the model's 0-999 coordinates to your actual screen/window resolution:
    *   `actual_x = (model_x / 1000) * window_width`
    *   `actual_y = (model_y / 1000) * window_height`
*   **Security & Permissions:** 
    *   Use a **dedicated browser profile** with limited permissions.
    *   Run in a **sandboxed environment** (Docker or VM) if possible to prevent accidental system changes.
    *   Ensure the model has clear visibility by using a standard resolution like **1440x900**.
