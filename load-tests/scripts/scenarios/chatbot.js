import http from 'k6/http';
import { check, sleep } from 'k6';
import { targets } from '../lib/config.js';
import { getAuthHeader } from '../lib/auth.js';

// NOTE: chatbot and product-translation hit external LLM vendors.
// Heavy load here mostly tests the vendor (and your wallet), not your infra.
// We keep this scenario small and rate-limited.

const PROMPTS = [
  'Show me trending products this week',
  'How long does shipping to Qatar take?',
  'What is your return policy?',
  'Recommend a gift under 200 QAR',
];

const TRANSLATE_SAMPLES = [
  { text: 'Wireless bluetooth headphones with noise cancelling', target: 'ar' },
  { text: 'Stainless steel water bottle 1 liter', target: 'ar' },
  { text: 'سماعات لاسلكية مع إلغاء الضوضاء', target: 'en' },
];

export function chatbotAndTranslation() {
  const auth = getAuthHeader();
  const headers = Object.assign({}, auth, { 'Content-Type': 'application/json' });

  // 50/50 between chatbot and translation.
  if (Math.random() < 0.5) {
    const prompt = PROMPTS[Math.floor(Math.random() * PROMPTS.length)];
    const r = http.post(
      `${targets.chatbot}/api/chat`,
      JSON.stringify({ message: prompt }),
      { headers, tags: { name: 'chatbot_message' }, timeout: '60s' },
    );
    check(r, { 'chat 2xx': (res) => res.status >= 200 && res.status < 300 });
  } else {
    const sample = TRANSLATE_SAMPLES[Math.floor(Math.random() * TRANSLATE_SAMPLES.length)];
    const r = http.post(
      `${targets.productTranslation}/translate`,
      JSON.stringify(sample),
      { headers, tags: { name: 'product_translation' }, timeout: '60s' },
    );
    check(r, { 'translate 2xx': (res) => res.status >= 200 && res.status < 300 });
  }

  // Long think time — LLM responses are slow; 1 VU ≈ 0.1 rps is realistic.
  sleep(5 + Math.random() * 5);
}
