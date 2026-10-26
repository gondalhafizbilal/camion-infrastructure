#!/usr/bin/env bash
# Fans out N copies of the k6 runner task on Fargate, waits for them all to finish,
# downloads per-shard summaries from S3, and prints an aggregate report.
#
# Required env (set by `terraform output run_command_hint`):
#   LT_CLUSTER, LT_TASK_DEF, LT_BUCKET, LT_SUBNETS, LT_SG
#
# Optional overrides:
#   TASK_COUNT          number of Fargate shards to launch (default: 10)
#   VUS_PER_TASK        VUs per shard (default: 1000)  → total VUs = TASK_COUNT * VUS_PER_TASK
#   DURATION            k6 duration (default: 10m)
#   AWS_PROFILE         AWS profile (default: camion-dev)
#   AWS_REGION          AWS region (default: eu-north-1)
#   TARGET_BACKEND/...  Override default targets per-run (any TARGET_* var is forwarded)

set -euo pipefail

: "${LT_CLUSTER:?source environments/load-test/eu-north-1 outputs first}"
: "${LT_TASK_DEF:?source environments/load-test/eu-north-1 outputs first}"
: "${LT_BUCKET:?source environments/load-test/eu-north-1 outputs first}"
: "${LT_SUBNETS:?source environments/load-test/eu-north-1 outputs first}"
: "${LT_SG:?source environments/load-test/eu-north-1 outputs first}"

TASK_COUNT="${TASK_COUNT:-10}"
VUS_PER_TASK="${VUS_PER_TASK:-1000}"
DURATION="${DURATION:-10m}"
AWS_PROFILE="${AWS_PROFILE:-camion-dev}"
AWS_REGION="${AWS_REGION:-eu-north-1}"
RUN_ID="${RUN_ID:-run-$(date -u +%Y%m%dT%H%M%SZ)}"

TOTAL_VUS=$((TASK_COUNT * VUS_PER_TASK))

echo "============================================================"
echo " Load test run"
echo "------------------------------------------------------------"
echo " RUN_ID       : ${RUN_ID}"
echo " Shards       : ${TASK_COUNT}"
echo " VUs/shard    : ${VUS_PER_TASK}"
echo " Total VUs    : ${TOTAL_VUS}"
echo " Duration     : ${DURATION}"
echo " Cluster      : ${LT_CLUSTER}"
echo " Results to   : s3://${LT_BUCKET}/runs/${RUN_ID}/"
echo "============================================================"
read -rp "Proceed? [y/N] " confirm
[[ "${confirm}" == "y" || "${confirm}" == "Y" ]] || { echo "aborted"; exit 1; }

aws() {
  command aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" "$@"
}

# Build the per-shard overrides array. Each shard gets the same VUS/DURATION
# but a unique TASK_INDEX. TARGET_* env vars from the caller's shell propagate through.
build_overrides() {
  local idx="$1"
  local env_pairs='[
    {"name":"RUN_ID","value":"'"${RUN_ID}"'"},
    {"name":"TASK_INDEX","value":"'"${idx}"'"},
    {"name":"TASK_COUNT","value":"'"${TASK_COUNT}"'"},
    {"name":"K6_VUS","value":"'"${VUS_PER_TASK}"'"},
    {"name":"K6_DURATION","value":"'"${DURATION}"'"}'
  for var in TARGET_FRONTEND TARGET_BACKEND TARGET_IMAGE_SERVICE TARGET_CHATBOT TARGET_PRODUCT_TRANSLATION \
             TEST_USER_POOL_SIZE TEST_USER_EMAIL_PATTERN TEST_USER_PASSWORD MAGIC_OTP SAMPLE_PRODUCT_IDS \
             K6_RAMP_UP K6_RAMP_DOWN; do
    if [[ -n "${!var:-}" ]]; then
      env_pairs+=',{"name":"'"${var}"'","value":"'"${!var}"'"}'
    fi
  done
  env_pairs+=']'
  cat <<JSON
{"containerOverrides":[{"name":"k6","environment":${env_pairs}}]}
JSON
}

declare -a TASK_ARNS

echo "Launching ${TASK_COUNT} Fargate tasks..."
for i in $(seq 0 $((TASK_COUNT - 1))); do
  overrides=$(build_overrides "$i")
  arn=$(aws ecs run-task \
    --cluster "${LT_CLUSTER}" \
    --task-definition "${LT_TASK_DEF}" \
    --launch-type FARGATE \
    --count 1 \
    --network-configuration "awsvpcConfiguration={subnets=[${LT_SUBNETS//,/,}],securityGroups=[${LT_SG}],assignPublicIp=DISABLED}" \
    --overrides "${overrides}" \
    --started-by "load-test-${RUN_ID}" \
    --query 'tasks[0].taskArn' --output text)
  echo "  shard ${i}: ${arn}"
  TASK_ARNS+=("${arn}")
done

echo
echo "Waiting for ${TASK_COUNT} tasks to finish (polling every 30s)..."
while true; do
  status=$(aws ecs describe-tasks \
    --cluster "${LT_CLUSTER}" \
    --tasks "${TASK_ARNS[@]}" \
    --query 'tasks[].lastStatus' --output text)
  pending=$(echo "${status}" | tr '\t' '\n' | grep -vc '^STOPPED$' || true)
  echo "  $(date -u +%H:%M:%S)  pending=${pending}/${TASK_COUNT}"
  [[ "${pending}" == "0" ]] && break
  sleep 30
done

echo
echo "All tasks stopped. Exit codes:"
aws ecs describe-tasks \
  --cluster "${LT_CLUSTER}" \
  --tasks "${TASK_ARNS[@]}" \
  --query 'tasks[].[taskArn,containers[0].exitCode,stoppedReason]' \
  --output table

echo
echo "Aggregating results from s3://${LT_BUCKET}/runs/${RUN_ID}/ ..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_ID="${RUN_ID}" AWS_PROFILE="${AWS_PROFILE}" AWS_REGION="${AWS_REGION}" LT_BUCKET="${LT_BUCKET}" \
  node "${SCRIPT_DIR}/summarize.js"
