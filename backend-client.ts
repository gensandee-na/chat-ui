import 'dotenv/config';
import fetch from 'node-fetch';
import { ChatCompletionResponse } from './types.js';

const BASE_URL = process.env.OPENAI_BASE_URL || 'https://router.huggingface.co/v1';
const API_KEY = process.env.OPENAI_API_KEY || process.env.HF_TOKEN || '';
const MODEL = process.env.LLM_MODEL || 'meta-llama/Llama-3.3-70B-Instruct';

export async function callChatBackend(prompt: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`Chat backend failed (${res.status}): ${errorText}`);
  }

  const data = (await res.json()) as ChatCompletionResponse;
  return data.choices[0].message.content;
}
