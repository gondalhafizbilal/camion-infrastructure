import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { targets } from '../lib/config.js';
import { getAuthHeader } from '../lib/auth.js';

// Logged-in core flow: view cart → list orders → add item → checkout (dry-run).
// Mutations are scoped to the per-VU test user so concurrent VUs don't collide.
export function backendCrud() {
  const auth = getAuthHeader();
  const headers = Object.assign({}, auth, { 'Content-Type': 'application/json' });

  group('cart_view', () => {
    const r = http.get(`${targets.backend}/cart`, {
      headers,
      tags: { name: 'cart_view' },
    });
    check(r, { 'cart 2xx': (res) => res.status >= 200 && res.status < 300 });
  });

  sleep(0.5 + Math.random() * 1.5);

  group('orders_list', () => {
    const r = http.get(`${targets.backend}/orders?page=1&limit=20`, {
      headers,
      tags: { name: 'orders_list' },
    });
    check(r, { 'orders 2xx': (res) => res.status >= 200 && res.status < 300 });
  });

  sleep(0.5 + Math.random() * 1.5);

  group('cart_add_item', () => {
    const productId = pickProductId();
    const r = http.post(
      `${targets.backend}/cart/items`,
      JSON.stringify({ productId, quantity: 1 }),
      { headers, tags: { name: 'cart_add_item' } },
    );
    check(r, { 'add item 2xx': (res) => res.status >= 200 && res.status < 300 });
  });

  sleep(0.5 + Math.random() * 1.5);
}

const SAMPLE_PRODUCT_IDS = (__ENV.SAMPLE_PRODUCT_IDS || '1,2,3,4,5,6,7,8,9,10').split(',');

function pickProductId() {
  return SAMPLE_PRODUCT_IDS[Math.floor(Math.random() * SAMPLE_PRODUCT_IDS.length)];
}
