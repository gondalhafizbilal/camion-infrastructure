#!/usr/bin/env node
// Reads runs/<RUN_ID>/*.json from S3 and prints an aggregate report.
// Zero npm dependencies — shells out to `aws s3` so we don't drag in @aws-sdk for one task.

const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const RUN_ID = required('RUN_ID');
const BUCKET = required('LT_BUCKET');
const PROFILE = process.env.AWS_PROFILE || 'camion-dev';
const REGION = process.env.AWS_REGION || 'eu-north-1';

function required(name) {
  const v = process.env[name];
  if (!v) { console.error(`Missing env: ${name}`); process.exit(2); }
  return v;
}

function aws(...args) {
  return execFileSync('aws', ['--profile', PROFILE, '--region', REGION, ...args], { encoding: 'utf8' });
}

const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'lt-results-'));
const s3Prefix = `s3://${BUCKET}/runs/${RUN_ID}/`;
console.log(`Downloading ${s3Prefix} -> ${tmpDir}`);
try {
  aws('s3', 'cp', s3Prefix, tmpDir, '--recursive');
} catch (err) {
  console.error("aws s3 cp failed — was any shard's summary uploaded?");
  console.error(err.message);
  process.exit(1);
}

const files = fs.readdirSync(tmpDir).filter((f) => f.endsWith('.json'));
if (files.length === 0) {
  console.error('No summary files found.');
  process.exit(1);
}

const shards = files.map((f) => JSON.parse(fs.readFileSync(path.join(tmpDir, f), 'utf8')));
console.log(`Loaded ${shards.length} shard summaries.\n`);

// Per-endpoint p95 = worst-case across shards (conservative, since shards see the same backend).
// http_req_failed rate = weighted by request count.
const perEndpoint = {};
let totalReqs = 0;
let totalFailed = 0;
let totalIters = 0;
let testDurSeconds = 0;
let anyBreach = false;

for (const s of shards) {
  const m = s.metrics || {};
  for (const [metric, info] of Object.entries(m)) {
    if (!metric.startsWith('http_req_duration')) continue;
    const subKey = metric === 'http_req_duration' ? '__all__' : metric;
    const v = info.values || {};
    perEndpoint[subKey] = perEndpoint[subKey] || { p50: 0, p95: 0, p99: 0, max: 0 };
    perEndpoint[subKey].p50 = Math.max(perEndpoint[subKey].p50, v['p(50)'] || 0);
    perEndpoint[subKey].p95 = Math.max(perEndpoint[subKey].p95, v['p(95)'] || 0);
    perEndpoint[subKey].p99 = Math.max(perEndpoint[subKey].p99, v['p(99)'] || 0);
    perEndpoint[subKey].max = Math.max(perEndpoint[subKey].max, v.max || 0);
  }
  const httpReqs = (m.http_reqs && m.http_reqs.values && m.http_reqs.values.count) || 0;
  const failed = (m.http_req_failed && m.http_req_failed.values && m.http_req_failed.values.passes) || 0;
  totalReqs += httpReqs;
  totalFailed += failed;
  totalIters += (m.iterations && m.iterations.values && m.iterations.values.count) || 0;
  const dur = (m.iteration_duration && m.iteration_duration.values && m.iteration_duration.values.max) || 0;
  testDurSeconds = Math.max(testDurSeconds, dur / 1000);

  for (const [metric, info] of Object.entries(m)) {
    if (!info.thresholds) continue;
    for (const [t, status] of Object.entries(info.thresholds)) {
      if (status && status.ok === false) {
        anyBreach = true;
      }
    }
  }
}

const errorRate = totalReqs > 0 ? (totalFailed / totalReqs) * 100 : 0;
const aggRps = testDurSeconds > 0 ? totalReqs / testDurSeconds : 0;

console.log('=== Aggregate ===');
console.log(`  Shards            : ${shards.length}`);
console.log(`  Total HTTP reqs   : ${totalReqs.toLocaleString()}`);
console.log(`  Total iterations  : ${totalIters.toLocaleString()}`);
console.log(`  Avg RPS           : ${aggRps.toFixed(1)}`);
console.log(`  Error rate        : ${errorRate.toFixed(3)}%`);
console.log('');
console.log('=== Latency (worst shard across cluster) ===');
console.log('  endpoint                                          p50      p95      p99      max');
for (const [name, v] of Object.entries(perEndpoint).sort()) {
  const short = name.length > 48 ? name.slice(0, 47) + '…' : name.padEnd(48);
  console.log(`  ${short}  ${ms(v.p50)}  ${ms(v.p95)}  ${ms(v.p99)}  ${ms(v.max)}`);
}

console.log('');
if (anyBreach) {
  console.log('THRESHOLDS: ❌ at least one shard breached an SLO threshold (see CloudWatch /ecs/load-test/k6-runner logs)');
  process.exit(1);
} else {
  console.log('THRESHOLDS: ✅ all SLOs met across all shards');
}

function ms(n) {
  if (!Number.isFinite(n)) return '     -';
  return (n < 10 ? n.toFixed(2) : n.toFixed(0)).padStart(7) + 'ms';
}
