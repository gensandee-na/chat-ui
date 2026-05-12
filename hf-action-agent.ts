import 'dotenv/config';
import { chromium, Page } from '@playwright/test';
import { callChatBackend } from './backend-client.js';

interface Action {
  type: 'goto' | 'fill' | 'click' | 'wait' | 'getText' | 'pressKey' | 'screenshot' | 'type' | 'click_at' | 'type_at' | 'done';
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  params: any;
}

async function getPageState(page: Page) {
  const viewport = page.viewportSize() || { width: 1280, height: 720 };
  const interactives = await page.evaluate(() => {
    const elements = Array.from(document.querySelectorAll('button, input, textarea, a, [role="button"]'));
    return elements.map(el => {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) return null;
      return {
        tag: el.tagName.toLowerCase(),
        text: (el as HTMLElement).innerText?.trim().slice(0, 50) || (el as HTMLInputElement).placeholder || (el as HTMLInputElement).name || (el as HTMLAnchorElement).href,
        id: el.id,
        role: el.getAttribute('role'),
        ariaLabel: el.getAttribute('aria-label'),
        // Provide normalized coordinates (0-999) for elements
        center: {
            x: Math.round(((rect.left + rect.width / 2) / window.innerWidth) * 1000),
            y: Math.round(((rect.top + rect.height / 2) / window.innerHeight) * 1000)
        }
      };
    }).filter(x => x !== null);
  });

  return { viewport, interactives };
}

async function executeAction(page: Page, action: Action): Promise<string | void> {
  const viewport = page.viewportSize() || { width: 1280, height: 720 };
  console.log(`Executing: ${action.type}`, action.params);
  
  try {
    switch (action.type) {
      case 'goto':
        await page.goto(action.params.url, { waitUntil: 'networkidle' });
        break;
      case 'fill':
        await page.waitForSelector(action.params.selector, { state: 'visible', timeout: 5000 });
        await page.fill(action.params.selector, action.params.text);
        break;
      case 'type':
        await page.waitForSelector(action.params.selector, { state: 'visible', timeout: 5000 });
        await page.type(action.params.selector, action.params.text);
        break;
      case 'click':
        await page.waitForSelector(action.params.selector, { state: 'visible', timeout: 5000 });
        await page.click(action.params.selector);
        break;
      case 'click_at': {
        const x = (action.params.x / 1000) * viewport.width;
        const y = (action.params.y / 1000) * viewport.height;
        await page.mouse.click(x, y);
        break;
      }
      case 'type_at': {
        const x = (action.params.x / 1000) * viewport.width;
        const y = (action.params.y / 1000) * viewport.height;
        await page.mouse.click(x, y);
        await page.keyboard.type(action.params.text);
        break;
      }
      case 'pressKey':
        await page.keyboard.press(action.params.key);
        break;
      case 'wait':
        if (action.params.selector) {
          await page.waitForSelector(action.params.selector, { state: 'attached', timeout: 5000 });
        } else if (action.params.timeout) {
          await new Promise(r => setTimeout(r, action.params.timeout));
        }
        break;
      case 'getText':
        await page.waitForSelector(action.params.selector, { state: 'attached', timeout: 5000 });
        return await page.innerText(action.params.selector);
      case 'screenshot':
        await page.screenshot({ path: action.params.path || 'debug.png' });
        break;
      case 'done':
        console.log("Agent finished task.");
        break;
    }
  } catch (err) {
    console.warn(`Action ${action.type} failed:`, (err as Error).message);
    return `Error: ${(err as Error).message}`;
  }
}

async function runAgent(task: string) {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 1280, height: 720 });

  let history: string[] = [];
  let step = 0;
  const maxSteps = 10;

  try {
    // Initial optional navigation
    const urlMatch = task.match(/https?:\/\/[^\s,)]+/);
    if (urlMatch) {
      const url = urlMatch[0].replace(/[.,!?;:^]$/, '');
      console.log(`Initial navigation to: ${url}`);
      await page.goto(url, { waitUntil: 'networkidle' });
    }

    while (step < maxSteps) {
      step++;
      const { viewport, interactives } = await getPageState(page);
      
      const systemPrompt = `You are a web automation agent. You perform tasks iteratively.
Current Viewport: ${viewport.width}x${viewport.height}
Coordinates: All x/y params use a 0-999 normalized grid.

Available actions (Output ONE at a time as a JSON object):
- { "type": "goto", "params": { "url": "..." } }
- { "type": "fill", "params": { "selector": "...", "text": "..." } } (DOM-based)
- { "type": "click", "params": { "selector": "..." } } (DOM-based)
- { "type": "click_at", "params": { "x": 500, "y": 500 } } (Coordinate-based)
- { "type": "type_at", "params": { "x": 500, "y": 500, "text": "..." } } (Coordinate-based)
- { "type": "pressKey", "params": { "key": "Enter" } }
- { "type": "wait", "params": { "timeout": 1000 } }
- { "type": "getText", "params": { "selector": "..." } }
- { "type": "done", "params": {} }

Rules:
1. Prefer text-based DOM selectors if available (e.g., 'a:has-text("Login")').
2. Use coordinates if DOM selectors are missing or unreliable.
3. Output ONLY the JSON object for the NEXT action.
4. If the task is finished, use "done".`;

      const userPrompt = `Task: ${task}
Step: ${step}
Interactive Elements: ${JSON.stringify(interactives)}
History: ${history.join(' -> ')}

Next Action:`;

      const response = await callChatBackend(`${systemPrompt}\n\n${userPrompt}`);
      const jsonStr = response.replace(/```json|```/g, '').trim();
      let action: Action;
      try {
        action = JSON.parse(jsonStr);
      } catch (e) {
        // Fallback if model doesn't return clean JSON
        const match = jsonStr.match(/\{.*\}/s);
        if (match) action = JSON.parse(match[0]);
        else throw new Error("Could not parse action JSON");
      }

      history.push(action.type);
      const result = await executeAction(page, action);
      
      if (action.type === 'done') break;
      if (result) history.push(`Result: ${result}`);
    }

    console.log('Task sequence completed.');
  } catch (err) {
    console.error('Agent failed:', err);
  } finally {
    await new Promise(r => setTimeout(r, 3000));
    await browser.close();
  }
}

const task = process.argv[2] || 'Go to https://news.ycombinator.com and find the top story text';
runAgent(task);
