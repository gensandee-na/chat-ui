import { Page } from '@playwright/test';

export async function sendMessageThroughUI(page: Page, message: string): Promise<string> {
  await page.goto('http://localhost:3000', { waitUntil: 'domcontentloaded' });

  const input = page.locator('textarea');
  await input.waitFor();
  await input.fill(message);

  await page.click('button:has-text("Send")');

  const lastMessage = page.locator('.message').last();
  await lastMessage.waitFor();

  return await lastMessage.innerText();
}
