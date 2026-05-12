# Playwright Best Practices & Resilient Selectors

This reference provides crucial strategies for writing robust, resilient selectors and avoiding "strict mode violations" in Playwright, based on the official documentation.

## 1. Prioritize User-Visible Locators
The most resilient way to locate elements is to mimic how a user finds them. Avoid CSS selectors (`.class-name`) or XPath when possible.

*   **`page.getByRole()` (Highly Recommended):** Locates elements by their ARIA role and accessible name. This is the most robust method because it relies on accessibility attributes that rarely change.
    *   *Example:* `page.getByRole('button', { name: 'Submit' })`
*   **`page.getByLabel()`:** Best for form fields where a `<label>` is associated with an `<input>`.
*   **`page.getByPlaceholder()`:** Use for inputs without labels but with placeholder text.
*   **`page.getByText()`:** Good for non-interactive elements like `div`, `span`, or `p`.
*   **`page.getByTestId()`:** Use when user-facing attributes are insufficient.

## 2. Avoiding Strict Mode Violations
A strict mode violation occurs when a locator matches multiple elements (e.g., `page.locator('a:has-text("new")')` resolving to 4 different links). Use these narrowing strategies to fix them:

*   **Be Specific with Roles:** Use the `name` option or `exact` flag.
    *   *Bad:* `page.getByRole('link', { name: 'new' })` (might match "news" or "new")
    *   *Good:* `page.getByRole('link', { name: 'new', exact: true })`
*   **Chaining Locators:** Narrow the search scope by finding a container first.
    ```javascript
    await page.getByRole('listitem')
              .filter({ hasText: 'Product 2' })
              .getByRole('button', { name: 'Add to cart' })
              .click();
    ```
*   **Filtering by Visibility:** If multiple elements match but only one is visible.
    ```javascript
    await page.locator('button:has-text("Submit")').filter({ visible: true }).click();
    ```
*   **Opt-out of Strictness (Last Resort):** Use `.first()`, `.last()`, or `.nth(index)`. Note: these are brittle if the DOM order changes.
    ```javascript
    await page.locator('a:has-text("new")').first().click();
    ```

## 3. General Best Practices
*   **Avoid Implementation Details:** Never rely on CSS classes or deep DOM paths (e.g., `div > div > button`). They break when the structure changes.
*   **Use Web-First Assertions:** Use `expect(locator).toBeVisible()` rather than `expect(await locator.isVisible()).toBe(true)`. Playwright automatically waits and retries web-first assertions.
*   **Regex for Dynamic Text:** For text with varying whitespace or dynamic parts: `page.getByText(/welcome, [A-Z]+/i)`.
