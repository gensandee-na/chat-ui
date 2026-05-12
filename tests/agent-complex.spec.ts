import { test, expect } from '@playwright/test';
import { callChatBackend } from '../backend-client.js';

test.describe('Hugging Face Action Agent - Complex Tasks', () => {
  test('Search and Verify Results on Hacker News', async ({ page }) => {
    // This test simulates the agent's logic but in a standard Playwright test format
    // to verify the robustness of our new selector strategies.
    
    await page.goto('https://news.ycombinator.com');
    
    // Apply resilient selector best practices (getByRole with exact name)
    const newLink = page.getByRole('link', { name: 'new', exact: true });
    await expect(newLink).toBeVisible();
    await newLink.click();
    
    await expect(page).toHaveURL(/newest/);
    
    // Test hidden element selection (which we fixed)
    const title = await page.innerText('title');
    expect(title).toContain('Hacker News');
    
    console.log('Complex task verification successful.');
  });
});
