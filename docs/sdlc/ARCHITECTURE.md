# Architecture — Camion Infrastructure

> Repository: `CamionOfficial/infrastructure` (Terraform / AWS)
> Region: `eu-north-1` (Stockholm) · Provider: `hashicorp/aws >= 6.13` · Terraform `>= 1.5.3`
> Last reviewed: 2026-06-03 (PROJECT INIT)

## 1. Overview

This repo is the **single source of truth for Camion's AWS infrastructure**, managed with
Terraform. Camion is an e-commerce / trading platform (domains `camiontrading.com` and
`camion-app.com`) running a set of containerised services on ECS Fargate behind a single
shared Application Load Balancer, fronted by Route 53 and CloudFront, backed by Aurora
PostgreSQL Serverless v2 and ElastiCache (Valkey).

The repo contains no application source — only infrastructure-as-code. Application images
are built and pushed by each service's own GitHub repository via OIDC-assumed roles defined
here (see §6 CI/CD).

## 2. Repository layout

```
infra/
├── backend-setup/                  CloudFormation that bootstraps the TF state backend
│   └── terraform-initialisation.yaml   (KMS key + S3 state bucket + DynamoDB lock table)
├── environments/                   Root modules — one dir per env per region
│   ├── dev/eu-north-1/             Account 167781471441, profile camion-dev
│   ├── prod/eu-north-1/            Account 377404936654, profile camion-prod
│   └── load-test/eu-north-1/       k6 Fargate load-test fleet (lives in dev account)
├── modules/                        Reusable in-repo modules (thin wrappers + custom)
│   ├── ecs/{cluster,service,container-definition}
│   ├── vpc/                         custom 3-tier VPC (public/private/data subnets)
│   ├── rds/  elasticache/redis/  load-balancer/  s3/  kms/  iam/general/
│   ├── cloudwatch/dashboards/  cloudformation/
└── load-tests/                     k6 scripts, Dockerfile, runner (separate concern)
```

Each environment root is a flat set of topic files (`alb.tf`, `rds.tf`, `redis.tf`,
`ssm.tf`, `iam.tf`, `vpc.tf`, `frontend.tf`, `chatbot.tf`, …) that compose the in-repo
modules and public Cloud Posse / terraform-aws-modules registry modules. `dev` and `prod`
have **identical file names** — they differ only by `terraform.tfvars` (sizing, domains,
deletion protection) and backend config.

## 3. Runtime architecture

```
                          Route 53 (dev.camiontrading.com zone)
                          DNS validation for ACM done manually in Hostinger
                                         │
                  ┌──────────────────────┴───────────────────────┐
                  ▼                                               ▼
        CloudFront (assets CDN)                       Application Load Balancer (HTTPS)
        S3 static-assets bucket                       host-header routing, 1 ALB shared:
        (OAC + KMS, lambda@edge)                        api.*        → backend  (8000)
                                                        app.*        → frontend (3000)
                                                        dashboard.*  → dashboard
                                                        chatbot.*    → chatbot
                                                        image-service.* → image-service
                                                        product-translation.* → pt-service
                                         │
                          ┌──────────────┴──────────────┐
                          ▼                              ▼
                  ECS Fargate services (per service: own cluster + ECR repo + service)
                  FARGATE_SPOT primary (weight 1), FARGATE fallback (base)
                  tasks run in PRIVATE subnets; ALB in PUBLIC subnets
                          │
          ┌───────────────┼───────────────────────┬──────────────────┐
          ▼               ▼                        ▼                  ▼
   Aurora PostgreSQL   ElastiCache Valkey     ElastiCache Valkey    S3 buckets
   Serverless v2       app_redis (cache)      bullmq_redis (jobs)   (assets, env, alb-logs)
   (DATA subnets)      (DATA subnets)         (DATA subnets)
```

### Network (custom VPC module)
Three-tier VPC per environment (`10.10.0.0/16` in dev) across 3 AZs
(`eu-north-1a/b/c`). Each AZ has a **public** subnet (ALB, NAT GW, IGW route), a
**private** subnet (ECS tasks, egress via NAT), and a **data** subnet (RDS, ElastiCache —
no internet route). Network ACLs are applied per tier. VPC Flow Logs are enabled to
CloudWatch. Gateway VPC endpoints for **S3** and **DynamoDB** and an interface endpoint for
**SSM** keep that traffic off the NAT path.

### Compute (ECS)
Each service gets its **own ECS cluster, ECR repo, and service** (not a shared cluster).
Clusters register both `FARGATE` and `FARGATE_SPOT` capacity providers; the service-level
strategy puts all weight on `FARGATE_SPOT` with `FARGATE` as the on-demand fallback to
control cost. Task definitions are built by the in-repo `ecs/container-definition` module.
Services support `enable_execute_command` (ECS Exec via SSM) for debugging.

### Data
- **Aurora PostgreSQL Serverless v2** (`cloudposse/rds-cluster`), engine 17.7, scales
  0→4 ACU in dev. Lives in data subnets, KMS-encrypted, master password managed by AWS
  (Secrets Manager, `manage_admin_user_password = true`). Performance Insights on.
- **ElastiCache (Valkey 7.2)** — two clusters: `app_redis` (cache / general) and
  `bullmq_redis` (BullMQ job queue). At-rest encryption on; dev runs single-node with
  failover disabled.

### Configuration & secrets
Runtime config is injected into ECS tasks two ways (see `backend.tf`):
- **Plain env vars** — only Terraform-derived, non-sensitive values (bucket names, region,
  Redis endpoint, `NODE_ENV`, `NODE_OPTIONS`).
- **Secrets** — everything sensitive is an **SSM Parameter Store SecureString** (or the
  Aurora-managed Secrets Manager secret for `DB_PASSWORD`) referenced via `valueFrom`.
  Integrations wired this way: SkipCash (payments), GullTrans, JOP WMS, Twilio, SendGrid,
  Mailchimp, Google/Facebook/Apple OAuth, product-translation, assets host.

### CDN / static assets
`cloudposse/cloudfront-s3-cdn` with Origin Access Control, a KMS-encrypted S3 origin
bucket, a dedicated ACM cert (validated via Hostinger DNS), and lambda@edge.

### Observability
- **CloudWatch dashboards** via `modules/cloudwatch/dashboards`.
- **CloudWatch metric alarms** driven by a single declarative `alarms` variable
  (`ecs-alarms.tf` for services, `data-alarms.tf` for RDS/ElastiCache). Each spec becomes
  an `aws_cloudwatch_metric_alarm` with dimensions resolved by namespace.
- **SNS topic** + subscriptions for alarm notifications; AWS Chatbot (`chatbot.tf`/Slack)
  integration present.
- **VPC Flow Logs** to CloudWatch.

## 4. Environments

| Env | Account | Profile | State key | Notable sizing |
|-----|---------|---------|-----------|----------------|
| dev | 167781471441 | `camion-dev` | `state/dev.state` | Aurora 0–4 ACU; cache.t3.small ×1; backend 2048/6144 |
| prod | 377404936654 | `camion-prod` | `state/prod.state` | larger CPU/mem (backend 4096/8192); deletion protection on; dual domains + alt/apex host headers |
| load-test | (dev account) | `camion-dev` | — | k6 Fargate fleet, 10k VUs, targets prod ALB over public internet |

State backend: per-account S3 bucket (`camion-terraform-<account-id>`) with KMS encryption
and a DynamoDB lock table (`dynamodb`), all bootstrapped by the CloudFormation template in
`backend-setup/`.

## 5. External dependencies / third parties
- **DNS registrar: Hostinger** — ACM cert validation CNAMEs are added manually there;
  Terraform does **not** auto-create validation records (`process_domain_validation_options
  = false`, `wait_for_certificate_issued = false`). Route 53 hosts the `dev.camiontrading.com`
  zone but the registrar/apex is external.
- Payment & logistics: SkipCash, GullTrans, JOP WMS. Comms: Twilio, SendGrid, Mailchimp.
  Auth: Google / Facebook / Apple. AI/search: Google API, JinaAI, Weaviate (chatbot &
  product-translation).
- Heavy use of **Cloud Posse** registry modules and **terraform-aws-modules**.

## 6. CI/CD
There is no Terraform pipeline in this repo — `terraform plan/apply` is run locally per
environment using the matching AWS profile (`mise.toml` sets `AWS_PROFILE`; note `mise.toml`
is gitignored). Application deployments use **GitHub Actions OIDC**: `iam.tf` defines a
deploy IAM role per service repo, each trusted via
`token.actions.githubusercontent.com:sub = repo:CamionOfficial/<repo>:environment:<env>`
with `aud = sts.amazonaws.com`. Roles grant scoped ECR push + `ecs:UpdateService`. Service
repos: `camion-frontend-v2`, `camion-dashboard-v2`, `chatbot-service`, `image-service`,
`product-translation-service` (backend repo uses the base `github-actions-deploy` policy).

## 7. Architectural Decision Records (ADRs)

ADRs below are **reconstructed** from the current code during INIT; they record decisions
already made, not new proposals.

### ADR-001 — Terraform with S3/DynamoDB remote state, bootstrapped by CloudFormation
**Status:** Accepted (in use). **Context:** Need durable, locked, encrypted TF state before
TF can run. **Decision:** A CloudFormation stack (`backend-setup/`) creates the KMS key, S3
state bucket, and DynamoDB lock table per account; TF backends reference them.
**Consequences:** Clean bootstrap with no chicken-and-egg; backend resources live outside TF
lifecycle. State buckets are account-scoped (`camion-terraform-<acct>`).

### ADR-002 — Per-service ECS cluster + ECR repo, not one shared cluster
**Status:** Accepted. **Context:** 6 independent services with independent deploy cadences.
**Decision:** Each service has its own cluster, ECR repo, and ECS service.
**Consequences:** Strong isolation and per-service IAM/scaling; more resources to manage and
some duplication across `*.tf` files.

### ADR-003 — FARGATE_SPOT primary with FARGATE fallback
**Status:** Accepted. **Context:** Cost control for non-critical-latency workloads.
**Decision:** Capacity-provider strategy weights all tasks to `FARGATE_SPOT`, keeping
`FARGATE` as on-demand fallback. **Consequences:** ~70% compute savings; tasks can be
interrupted — acceptable given ALB health checks and multi-task services. Revisit for
latency-critical/stateful services.

### ADR-004 — Secrets via SSM Parameter Store SecureString, not plaintext env
**Status:** Accepted. **Context:** Many third-party credentials must reach the backend.
**Decision:** Only TF-derived non-sensitive values are plain env vars; everything sensitive
is an SSM SecureString referenced by `valueFrom`; DB password comes from the Aurora-managed
Secrets Manager secret. **Consequences:** Secrets never appear in task defs or state in
plaintext; rotation is centralised; KMS decrypt permissions scoped to task roles.

### ADR-005 — Aurora PostgreSQL Serverless v2
**Status:** Accepted. **Context:** Spiky / low dev load; want managed scaling.
**Decision:** `db.serverless` with `serverlessv2_scaling_configuration` (0–4 ACU dev).
**Consequences:** Scales down when idle to save cost; managed master password; cold-start
latency on scale-up is accepted (backend has a 60s ALB health-check grace period).

### ADR-006 — Single shared ALB with host-header routing
**Status:** Accepted. **Context:** 6 services need public HTTPS ingress.
**Decision:** One ALB, HTTPS listener rules route by host header to per-service target
groups (priorities 50–300). **Consequences:** One cert/ALB to manage and pay for; all
services share ingress fate. Prod adds `alt_host_header`/`apex_host_header` for dual domains.

### ADR-007 — DNS validation handled manually in Hostinger
**Status:** Accepted (constraint). **Context:** Registrar is Hostinger, not Route 53.
**Decision:** ACM requests don't auto-create or wait on validation records; operator copies
CNAMEs from `terraform output` into Hostinger. **Consequences:** Two-step apply for new
certs; documented in `alb.tf` / `static-assets.tf` comments. Candidate for future migration
of DNS to Route 53.

### ADR-008 — Custom VPC module with explicit 3-tier subnets + NACLs
**Status:** Accepted. **Context:** Want clear network segmentation and control.
**Decision:** In-repo `modules/vpc` builds public/private/data subnets per AZ with NACLs,
flow logs, NAT, and S3/DynamoDB/SSM VPC endpoints rather than relying solely on a registry
module. **Consequences:** Full control and data-tier isolation; more module code to maintain.

## 8. Known constraints & risks (see PROJECT-PLAN.md for the prioritised backlog)
- No automated CI for `terraform fmt/validate/plan` or policy checks; applies are manual.
- `tfplan`/`*.plan` files are committed in env dirs (gitignored going forward, but present).
- Dev data tier is single-node with failover disabled (acceptable for dev, not prod).
- DNS validation is a manual out-of-band step.
- No `tflint`/`checkov`/`tfsec`/`terraform-docs` automation present.
