#!/usr/bin/env bash
# Runs inside each Fargate task. Reads coordination env vars set by `aws ecs run-task`
# (RUN_ID, TASK_INDEX, TASK_COUNT, K6_VUS, K6_DURATION), executes k6, and uploads the
# JSON summary to S3 under runs/<RUN_ID>/<TASK_INDEX>.json.

set -euo pipefail

: "${RESULTS_BUCKET:?RESULTS_BUCKET required (set by Terraform task def)}"
: "${RUN_ID:?RUN_ID required (set per-run by run.sh)}"
: "${TASK_INDEX:?TASK_INDEX required (set per-run by run.sh)}"
: "${TASK_COUNT:?TASK_COUNT required (set per-run by run.sh)}"

VUS="${K6_VUS:-${DEFAULT_VUS:-1000}}"
DURATION="${K6_DURATION:-${DEFAULT_DURATION:-10m}}"

echo "[entrypoint] run=${RUN_ID} shard=${TASK_INDEX}/${TASK_COUNT} vus=${VUS} duration=${DURATION}"
echo "[entrypoint] targets: backend=${TARGET_BACKEND} frontend=${TARGET_FRONTEND}"

# k6 reads scenarios from main.js; --vus/--duration here are overridden per-scenario
# by the stages defined in options. We still pass them so DEFAULT_VUS gets propagated
# via env, and so explicit CLI overrides work.
set +e
k6 run \
  --tag run_id="${RUN_ID}" \
  --tag shard="${TASK_INDEX}" \
  --summary-export=/tmp/summary-export.json \
  /app/scripts/main.js
K6_EXIT=$?
set -e

DEST="s3://${RESULTS_BUCKET}/runs/${RUN_ID}/${TASK_INDEX}.json"
echo "[entrypoint] k6 exit=${K6_EXIT}, uploading summary to ${DEST}"

# Prefer the handleSummary output (richer); fall back to --summary-export.
if [[ -f /tmp/summary.json ]]; then
  aws s3 cp /tmp/summary.json "${DEST}"
elif [[ -f /tmp/summary-export.json ]]; then
  aws s3 cp /tmp/summary-export.json "${DEST}"
else
  echo "[entrypoint] WARN: no summary file produced by k6" >&2
fi

# Surface k6's exit code so ECS marks the task FAILED on threshold breach.
exit "${K6_EXIT}"
