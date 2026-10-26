import http from 'k6/http';
import { check, sleep } from 'k6';
import { targets } from '../lib/config.js';
import { getAuthHeader } from '../lib/auth.js';

// Fixture is baked into the container at /scripts/fixtures/sample-image.jpg.
// open() must be at module init time per k6's rules.
const sampleImage = open('../fixtures/sample-image.jpg', 'b');

export function imageUpload() {
  const auth = getAuthHeader();

  const form = {
    file: http.file(sampleImage, 'sample.jpg', 'image/jpeg'),
  };

  const r = http.post(`${targets.imageService}/upload`, form, {
    headers: auth,
    tags: { name: 'image_upload' },
    timeout: '60s',
  });

  check(r, {
    'upload 2xx': (res) => res.status >= 200 && res.status < 300,
  });

  sleep(2 + Math.random() * 3);
}
