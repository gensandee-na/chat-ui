# Chat-UI Selectors

This reference provides a list of robust CSS selectors for the `chat-ui` application.

## Navigation
- **New Chat**: `button:has-text("New Chat")`, `[data-testid="new-chat"]`
- **Settings**: `a[href="/settings"]`, `[data-testid="settings-link"]`
- **Login Link**: `a[href="/login"]`
- **Logout Button**: `button:has-text("Sign Out")`

## Chat Interface
- **Message Input**: `textarea`, `textarea[placeholder*="Ask"]`, `[data-testid="chat-input"]`
- **Send Button**: `button[type="submit"]`, `button:has(svg.i-carbon-send)`
- **Stop Generation**: `button:has-text("Stop")`
- **Last Bot Message**: `.prose:last-child`, `.message:not(.user):last-child`
- **Message Feedback (Like/Dislike)**: `.feedback-buttons button`

## Settings
- **Theme Selector**: `select[name="theme"]`
- **Model Selector**: `select[name="model"]`
- **Save Settings**: `button:has-text("Save")`

## Assistant / Tools
- **Assistant List**: `.assistant-card`
- **Tool Toggle**: `.tool-toggle`
- **Mcp Server Status**: `.mcp-status-indicator`
