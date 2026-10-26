import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { targets } from '../lib/config.js';

// Anonymous browsing — heaviest share of real traffic. Hits CloudFront/ALB and
// the frontend SSR pages.
export function frontendBrowse() {
  group('frontend_home', () => {
    const r = http.get(`${targets.frontend}/en`, {
      tags: { name: 'frontend_home' },
    });
    check(r, { 'home 2xx': (res) => res.status >= 200 && res.status < 400 });
  });

  sleep(thinkTime());

  group('frontend_catalog', () => {
    const r = http.get(`${targets.frontend}/en/products`, {
      tags: { name: 'frontend_catalog' },
    });
    check(r, { 'catalog 2xx': (res) => res.status >= 200 && res.status < 400 });
  });

  sleep(thinkTime());

  group('frontend_product_detail', () => {
    const pid = pickProductId();
    const r = http.get(`${targets.frontend}/en/products/${pid}`, {
      tags: { name: 'frontend_product_detail' },
    });
    check(r, { 'product 2xx': (res) => res.status >= 200 && res.status < 400 });
  });

  sleep(thinkTime());
}

function thinkTime() {
  // 1-5s think time keeps each VU's RPS realistic (~0.3-1 rps), so 1000 VUs ≈ 300-1000 rps.
  return 1 + Math.random() * 4;
}

const SAMPLE_PRODUCT_IDS = (__ENV.SAMPLE_PRODUCT_IDS || '1,2,3,4,5,6,7,8,9,10').split(',');

function pickProductId() {
  return SAMPLE_PRODUCT_IDS[Math.floor(Math.random() * SAMPLE_PRODUCT_IDS.length)];
}
