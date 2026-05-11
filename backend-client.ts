import fetch from 'node-fetch';
import { ChatCompletionResponse } from './types.js';

export async function callChatBackend(prompt: string): Promise<string> {
  const res = await fetch('http://localhost:11434/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'llama3',
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  const data = (await res.json()) as ChatCompletionResponse;
  return data.choices[0].message.content;
}
