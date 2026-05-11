import { chromium } from '@playwright/test';
import { sendMessageThroughUI } from './chatui-driver.js';
import { callChatBackend } from './backend-client.js';
import { JobResult } from './types.js';

let shuttingDown = false;

async function runJob(id: number): Promise<JobResult> {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    const uiReply = await sendMessageThroughUI(page, `Job ${id} automated message`);
    const backendReply = await callChatBackend(`Job ${id} backend request`);

    console.log(`UI reply: ${uiReply}`);
    console.log(`Backend reply: ${backendReply}`);

    return {
      id,
      uiReply,
      backendReply,
      timestamp: new Date().toISOString(),
    };
  } finally {
    await browser.close();
  }
}

async function main() {
  let id = 0;

  process.on('SIGINT', () => {
    console.log('Received SIGINT, shutting down...');
    shuttingDown = true;
  });
  process.on('SIGTERM', () => {
    console.log('Received SIGTERM, shutting down...');
    shuttingDown = true;
  });

  while (!shuttingDown) {
    id++;
    try {
      await runJob(id);
    } catch (err) {
      console.error(`Job ${id} failed:`, err);
    }
    await new Promise((r) => setTimeout(r, 30000));
  }

  console.log('Worker exited cleanly.');
}

main();
