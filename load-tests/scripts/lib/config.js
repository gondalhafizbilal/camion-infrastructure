// All targets are env-driven so the same image runs against prod, dev, or a staging copy.
// Defaults are baked in by the Terraform task definition; CLI overrides are passed via run.sh.

function required(name) {
  const v = __ENV[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

function optional(name, fallback) {
  return __ENV[name] || fallback;
}

export const targets = {
  frontend:           required('TARGET_FRONTEND'),
  backend:            required('TARGET_BACKEND'),
  imageService:       required('TARGET_IMAGE_SERVICE'),
  chatbot:            required('TARGET_CHATBOT'),
  productTranslation: required('TARGET_PRODUCT_TRANSLATION'),
};

// Each runner task gets its own shard. Tasks coordinate purely via TASK_INDEX/TASK_COUNT
// so we don't need a control plane.
export const shard = {
  index: parseInt(optional('TASK_INDEX', '0'), 10),
  count: parseInt(optional('TASK_COUNT', '1'), 10),
  runId: optional('RUN_ID', 'local'),
};

// Test user pool — pre-seeded in the target env. The pool is sharded across runner tasks
// so two VUs don't try to mutate the same user simultaneously.
export const testUsers = {
  poolSize:     parseInt(optional('TEST_USER_POOL_SIZE', '5000'), 10),
  emailPattern: optional('TEST_USER_EMAIL_PATTERN', 'loadtest+{id}@camiontrading.com'),
  password:     optional('TEST_USER_PASSWORD', 'LoadTest!2026'),
  magicOtp:     optional('MAGIC_OTP', '123456'),
};

// Per-shard user-id range. With 5000 users and 10 tasks → each task owns 500 users.
export function userIdForVu(vuId) {
  const perShard = Math.floor(testUsers.poolSize / shard.count);
  const base = shard.index * perShard;
  return base + (vuId % perShard);
}

export function userEmail(userId) {
  return testUsers.emailPattern.replace('{id}', String(userId));
}

// Traffic mix — tuned for an ecommerce-style app. Sums to 100.
// Anonymous-only override for the first prod run: 100% frontend browse, no auth.
export const mix = {
  frontendBrowse:    100,
  backendCrud:       0,
  chatbot:           0,
  imageUpload:       0,
};

// Common headers / behavior knobs.
export const httpDefaults = {
  timeout: '30s',
  userAgent: `k6-load-test/${shard.runId}`,
};
