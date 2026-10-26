# Load tests

Distributed k6 load test that drives **10,000 concurrent users** against the Camion stack from a Fargate fleet in the dev AWS account. Targets prod (configurable) over the public ALB — no VPC peering required.

## Architecture

```
┌────────────── camion-dev account (eu-north-1) ──────────────┐
│                                                              │
│   ECS cluster "load-test-k6-runner"  (Fargate)               │
│       │                                                      │
│       ├── shard 0  (4 vCPU / 8 GiB, 1000 VUs)  ──┐           │
│       ├── shard 1  ...                            │          │
│       ├── ...                                     │ public   │
│       └── shard 9                                 │ internet │
│                                                   ▼          │
└───────────────────────────────────────────────────┼──────────┘
                                                    │
                                                    ▼
                              api.camion-app.com, app.camion-app.com, ...
                              (camion-prod ALB)
```

Each shard runs the same k6 main.js with a unique `TASK_INDEX`; the user pool is sharded so two VUs never hit the same test user. Per-shard JSON summaries land in `s3://camion-load-test-results-<account>/runs/<RUN_ID>/`, then `summarize.js` aggregates them locally.

## Prereqs

1. **AWS CLI** configured with the `camion-dev` profile.
2. **Docker** for building the runner image.
3. **Node 18+** for `summarize.js`.
4. **Terraform 1.5+**.
5. **k6 0.51+** locally (optional — only needed to dry-run scripts before pushing).
6. A **test-user pool** in the target environment. By default the scripts assume:
   - `loadtest+0@camiontrading.com` through `loadtest+4999@camiontrading.com`
   - `MAGIC_OTP=123456` enabled for those addresses (already true in dev)
   - For **prod**, you must seed the pool and enable MAGIC_OTP for those specific users in the backend — see "Targeting prod" below.
7. A fixture image at `scripts/fixtures/sample-image.jpg` (see that dir's README).

## One-time setup

```sh
cd environments/load-test/eu-north-1
terraform init
terraform apply
```

Outputs (`terraform output run_command_hint`) include the env-var block you need to source before running:

```sh
export LT_CLUSTER=...
export LT_TASK_DEF=...
export LT_BUCKET=...
export LT_SUBNETS=...
export LT_SG=...
```

## Build and push the runner image

```sh
cd load-tests

# Add a fixture image first (see scripts/fixtures/README.md)
curl -sSL https://picsum.photos/800/600.jpg -o scripts/fixtures/sample-image.jpg

ECR_URL=$(cd ../environments/load-test/eu-north-1 && terraform output -raw ecr_repository_url)

aws ecr get-login-password --profile camion-dev --region eu-north-1 \
  | docker login --username AWS --password-stdin "${ECR_URL%/*}"

docker build --platform linux/amd64 -t "${ECR_URL}:latest" .
docker push "${ECR_URL}:latest"
```

Rebuild + push any time you edit a `scripts/*.js` file.

## Run a 10k-user test

```sh
cd load-tests
eval "$(cd ../environments/load-test/eu-north-1 && terraform output -raw run_command_hint)"

# 10 shards * 1000 VUs = 10,000 concurrent users, 10 min steady state
./run.sh
```

`run.sh` will:
1. Confirm before launching (it asks `Proceed? [y/N]`).
2. Launch N Fargate tasks via `aws ecs run-task`.
3. Poll until all are `STOPPED`.
4. Print each task's exit code.
5. Download per-shard summaries from S3 and print an aggregate report.

### Smaller smoke run

```sh
TASK_COUNT=2 VUS_PER_TASK=100 DURATION=2m ./run.sh
```

### Point at a different env

```sh
TARGET_BACKEND="https://api.dev.camiontrading.com" \
TARGET_FRONTEND="https://app.dev.camiontrading.com" \
TARGET_IMAGE_SERVICE="https://image-service.dev.camiontrading.com" \
TARGET_CHATBOT="https://chatbot.dev.camiontrading.com" \
TARGET_PRODUCT_TRANSLATION="https://product-translation.dev.camiontrading.com" \
TASK_COUNT=10 VUS_PER_TASK=1000 DURATION=10m \
./run.sh
```

## Reading the output

`summarize.js` prints:

- **Total HTTP reqs / RPS / error rate** — the headline numbers.
- **Latency table** per endpoint name: p50, p95, p99, max (worst across shards).
- **Threshold status** — overall pass/fail against the SLOs in `scripts/main.js` (currently: p95<1.5s overall, <1% errors, per-endpoint sub-SLAs).

CloudWatch logs are at `/ecs/load-test/k6-runner` for live tailing during a run:

```sh
aws logs tail /ecs/load-test/k6-runner --follow --profile camion-dev --region eu-north-1
```

## Cost per run

Fargate on-demand in eu-north-1: ~$0.04/vCPU-hr + $0.0045/GiB-hr.

| TASK_COUNT × CPU × DURATION | vCPU-hours | GiB-hours | Fargate cost |
|---|---|---|---|
| 10 × 4 vCPU × 10 min (10k VUs) | 6.7 | 13.3 | ~**$0.33** |
| 10 × 4 vCPU × 30 min          | 20  | 40   | ~**$1.00** |

Plus negligible S3 (kB per run), CloudWatch logs (few cents), and **whatever traffic costs hit prod** (egress, RDS load, etc.).

## Targeting prod — safety checklist

The defaults point at prod. Before pulling the trigger:

1. **Notify on-call.** A real 10k-VU run will be visible in your dashboards, alarms, and likely your error budget.
2. **Pick a low-traffic window.** Off-hours for your user base.
3. **Use a real test-tenant.** The script logs in as `loadtest+N@camiontrading.com`. In prod, those accounts:
   - Must exist (seed them ahead of time — 5000 rows).
   - Must have `ENABLE_MAGIC_OTP=true` scoped to them, OR you must replace `lib/auth.js` with a real OTP flow.
   - Should be flagged as test users so they don't pollute analytics, fraud rules, payment gateways, SMS quotas (Twilio!), email quotas (SendGrid!), or the data warehouse.
4. **Disable mutations you can't afford.** The default mix includes `cart_add_item`. Comment that out in `backend-crud.js` if cart writes would corrupt prod state.
5. **Have an abort plan.** To kill the run mid-flight:
   ```sh
   aws ecs list-tasks --cluster "${LT_CLUSTER}" --started-by "load-test-${RUN_ID}" \
     --query 'taskArns[]' --output text --profile camion-dev | \
     xargs -n1 aws ecs stop-task --cluster "${LT_CLUSTER}" --profile camion-dev --task
   ```
6. **Watch out for vendor blast radius.** The `chatbot` and `product-translation` scenarios hit Google / Jina / Weaviate / Twilio / SendGrid. At 1000+ concurrent, you may hit *their* rate limits and rack up cost. Set `mix.chatbot = 0` and `mix.imageUpload = 0` in `lib/config.js` for a pure-infra run.

## Capacity math for 10k concurrent

- k6 on a 4 vCPU / 8 GiB Fargate task handles ~1000–2000 HTTP-heavy VUs comfortably. We size for the lower end (1000) to leave headroom for the multipart upload scenario.
- 10 shards × 1000 VUs = **10,000 concurrent users**.
- At avg think time ~3s per iteration, expect ~3000–4000 RPS aggregate against the backend.
- To go higher: bump `task_count` in `terraform.tfvars` (the limit becomes Fargate vCPU quota in the dev account — currently 6000 by default, ~25× headroom).

## File map

```
environments/load-test/eu-north-1/
  terraform.tf       # backend (state in camion-dev account)
  main.tf            # provider + data sources for dev VPC
  variables.tf
  terraform.tfvars   # all knobs live here
  ecr.tf             # runner image registry
  ecs.tf             # cluster + task definition
  iam.tf             # task & exec roles (S3 write only)
  s3.tf              # results bucket
  cloudwatch.tf      # log group
  outputs.tf         # exports for run.sh

load-tests/
  Dockerfile         # grafana/k6 + scripts + awscli
  entrypoint.sh      # in-container runner
  run.sh             # orchestrator (fans out Fargate tasks)
  summarize.js       # aggregates per-shard results
  scripts/
    main.js          # k6 scenarios + thresholds
    lib/
      config.js      # env-driven targets + sharding
      auth.js        # OTP login + per-VU token cache
    scenarios/
      frontend-browse.js
      backend-crud.js
      image-upload.js
      chatbot.js
    fixtures/
      README.md      # how to drop in sample-image.jpg
```
