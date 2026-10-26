// Entry point. k6 runs this with: k6 run --vus N --duration D scripts/main.js
// One k6 process = one runner shard. N shards × VUS_PER_SHARD = total concurrent users.

import { mix, shard } from './lib/config.js';
import { frontendBrowse } from './scenarios/frontend-browse.js';
import { backendCrud } from './scenarios/backend-crud.js';
import { imageUpload } from './scenarios/image-upload.js';
import { chatbotAndTranslation } from './scenarios/chatbot.js';

// VU allocation across scenarios derived from mix percentages. k6 reads `options` at
// init time so we compute from env vars rather than re-deriving each iteration.
const VUS = parseInt(__ENV.K6_VUS || __ENV.DEFAULT_VUS || '1000', 10);
const DURATION = __ENV.K6_DURATION || __ENV.DEFAULT_DURATION || '10m';
const RAMP_UP = __ENV.K6_RAMP_UP || '2m';
const RAMP_DOWN = __ENV.K6_RAMP_DOWN || '1m';

function vusFor(pct) {
  return Math.round((VUS * pct) / 100);
}

function stages(targetVus) {
  return [
    { duration: RAMP_UP, target: targetVus },
    { duration: DURATION, target: targetVus },
    { duration: RAMP_DOWN, target: 0 },
  ];
}

// Scenarios with mix === 0 are skipped entirely so we don't spin up 1-VU placeholder scenarios.
const scenarioDefs = {
  frontend_browse: { exec: 'sFrontendBrowse', pct: mix.frontendBrowse },
  backend_crud:    { exec: 'sBackendCrud',    pct: mix.backendCrud },
  image_upload:    { exec: 'sImageUpload',    pct: mix.imageUpload },
  chatbot:         { exec: 'sChatbot',        pct: mix.chatbot },
};

const enabledScenarios = {};
for (const [name, def] of Object.entries(scenarioDefs)) {
  if (def.pct > 0) {
    enabledScenarios[name] = {
      executor: 'ramping-vus',
      exec: def.exec,
      startVUs: 0,
      stages: stages(vusFor(def.pct)),
      gracefulRampDown: '30s',
    };
  }
}

export const options = {
  scenarios: enabledScenarios,

  // SLOs — adjust to your contractual targets. Breaches fail the run (non-zero exit).
  thresholds: {
    'http_req_failed':   ['rate<0.01'],          // <1% errors overall
    'http_req_duration': ['p(95)<1500', 'p(99)<3000'],
    'http_req_duration{name:frontend_home}':         ['p(95)<800'],
    'http_req_duration{name:frontend_catalog}':      ['p(95)<1200'],
    'http_req_duration{name:cart_view}':             ['p(95)<500'],
    'http_req_duration{name:cart_add_item}':         ['p(95)<800'],
    'http_req_duration{name:image_upload}':          ['p(95)<5000'],
    // LLM-backed paths are dominated by vendor latency — looser threshold.
    'http_req_duration{name:chatbot_message}':       ['p(95)<10000'],
    'http_req_duration{name:product_translation}':   ['p(95)<8000'],
  },

  // Each VU keeps connections alive. Fewer TCP setups = more realistic browser behavior.
  noConnectionReuse: false,
  discardResponseBodies: true,

  // Tag every metric with the run id and shard for downstream aggregation.
  tags: {
    run_id: shard.runId,
    shard:  String(shard.index),
  },

  // Realistic ECS task limits — fail fast if VU init is starved.
  setupTimeout: '60s',
  teardownTimeout: '60s',
};

export function sFrontendBrowse()  { frontendBrowse(); }
export function sBackendCrud()     { backendCrud(); }
export function sImageUpload()     { imageUpload(); }
export function sChatbot()         { chatbotAndTranslation(); }

// k6 calls this default export only when no `exec` is set; ours always set exec.
export default function () {
  frontendBrowse();
}

// handleSummary runs once at the end of the shard. We emit a compact JSON that
// run.sh's summarize.js can fan-in across all shards.
export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    '/tmp/summary.json': JSON.stringify({
      runId:    shard.runId,
      shard:    shard.index,
      shards:   shard.count,
      metrics:  data.metrics,
      state:    data.state,
      thresholds: extractThresholdStatus(data),
    }, null, 2),
  };
}

function textSummary(data) {
  const lines = [];
  lines.push('');
  lines.push(`=== Shard ${shard.index}/${shard.count} (run ${shard.runId}) ===`);
  const httpDur = data.metrics.http_req_duration && data.metrics.http_req_duration.values;
  const httpFail = data.metrics.http_req_failed && data.metrics.http_req_failed.values;
  if (httpDur) {
    lines.push(`http_req_duration  p50=${fmt(httpDur['p(50)'])}ms p95=${fmt(httpDur['p(95)'])}ms p99=${fmt(httpDur['p(99)'])}ms`);
  }
  if (httpFail) {
    lines.push(`http_req_failed    rate=${(httpFail.rate * 100).toFixed(2)}%`);
  }
  const iters = data.metrics.iterations && data.metrics.iterations.values;
  if (iters) {
    lines.push(`iterations         count=${iters.count} rate=${fmt(iters.rate)}/s`);
  }
  lines.push('');
  return lines.join('\n');
}

function fmt(n) {
  if (n == null) return '-';
  return n < 10 ? n.toFixed(2) : n.toFixed(0);
}

function extractThresholdStatus(data) {
  const out = {};
  for (const [metric, info] of Object.entries(data.metrics || {})) {
    if (info.thresholds) {
      out[metric] = info.thresholds;
    }
  }
  return out;
}
