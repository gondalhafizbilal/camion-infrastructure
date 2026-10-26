# MEMORY — Camion Infrastructure

> Persistent, deduplicated ground truth. Read this first on every task; update it last.
> Detailed docs: `ARCHITECTURE.md`, `PATTERNS.md`, `PROJECT-PLAN.md`, `specs/<feature>/`.

## What this repo is
Terraform IaC for Camion's AWS estate (e-commerce: `camiontrading.com` / `camion-app.com`).
No application source here — only infra. Region `eu-north-1`. TF `>= 1.5.3`, AWS provider
`>= 6.13`.

## Key facts (stable)
- **Environments:** `dev` (acct 167781471441, profile `camion-dev`), `prod` (acct
  377404936654, profile `camion-prod`), plus a `load-test` k6 fleet in the dev account.
  dev/prod root modules share identical file names; differences live in `terraform.tfvars`.
- **State backend:** per-account S3 bucket `camion-terraform-<acct>` + DynamoDB lock table
  `dynamodb`, KMS-encrypted, bootstrapped by `backend-setup/terraform-initialisation.yaml`
  (CloudFormation).
- **Services (6):** backend(8000), frontend(3000), dashboard, chatbot, image-service,
  product-translation. Each = own ECS cluster + ECR repo + service. Routed by one shared
  ALB via host headers (api./app./dashboard./chatbot./image-service./product-translation.).
- **Compute:** ECS Fargate, `FARGATE_SPOT` primary + `FARGATE` fallback. Tasks in private
  subnets; ALB in public. ECS Exec enabled.
- **Data:** Aurora PostgreSQL Serverless v2 (engine 17.7, 0–4 ACU dev, managed master
  password). ElastiCache Valkey 7.2 ×2: `app_redis` (cache) + `bullmq_redis` (queue). Both
  in data subnets, encrypted at rest.
- **Secrets:** sensitive values = SSM SecureString referenced via `valueFrom`; only
  TF-derived non-sensitive values are plain env. DB password from Aurora-managed Secrets
  Manager secret. `terraform.tfvars`, `*.env`, comparison reports are gitignored.
- **CDN:** CloudFront + S3 (OAC, KMS, lambda@edge) for static assets.
- **Edge security (dev + prod):** WAFv2 web ACL `camion-<env>-alb` on the ALB via
  `cloudposse/waf/aws` (`waf.tf`), COUNT mode only — DDoS (IP-reputation + anonymous-IP),
  scraping (Common Rule Set), per-IP rate limit (2000/5min). Driven by `var.waf` (all
  count-mode config in its defaults, `default = {}`, so dev/prod `waf.tf`+`var.waf` are
  identical); Bot Control gated off by default. **APPLIED: dev 2026-06-08, prod 2026-06-09**
  (both targeted, 5 add each). Next step is selective enforce (count→block). Spec:
  `specs/waf-dev-alb/`.
- **Observability:** CloudWatch dashboards + declarative `alarms` var → metric alarms →
  shared SNS topic; AWS Chatbot/Slack; VPC Flow Logs.
- **CI/CD:** No TF pipeline — applies are manual/local with the env AWS profile. App deploys
  use GitHub OIDC roles (`iam.tf`), one per service repo, scoped ECR push + `ecs:Update
  Service`, trust `repo:CamionOfficial/<repo>:environment:<env>`.
- **DNS:** Route 53 hosts `dev.camiontrading.com`; registrar is **Hostinger** — ACM
  validation CNAMEs added manually (no auto Route 53 records, no wait-for-issued).
- **Modules:** heavy Cloud Posse + terraform-aws-modules use; custom in-repo modules for
  ecs/{cluster,service,container-definition}, vpc (3-tier), load-balancer, kms, s3,
  iam/general, cloudwatch/dashboards.

## Conventions (see PATTERNS.md for full)
- New service ⇒ add identical `<service>.tf` in dev and prod; vary only via tfvars.
- Secrets ⇒ SSM SecureString + `valueFrom`, never plaintext. **Real values are NOT put
  inline in `.tf`** — TF owns only a placeholder param (`value = "CHANGE_ME"` +
  `lifecycle { ignore_changes = [value] }`) and the `valueFrom` wiring; the value is seeded
  out-of-band via `aws ssm put-parameter --overwrite` (the `apple_private_key` pattern).
  Older params (skipcash, chatbot Weaviate/Jina) still have values inline — don't copy that.
  Tag everything with `common_tags`. Data stores ⇒ data subnets, least-privilege SGs/IAM.
- Don't commit `*.tfplan`/`*.plan`, `*.tfvars`, `*.env`, `mise.toml`.

## Open items / watchlist (see PROJECT-PLAN.md backlog)
- P0: committed `*.tfplan`/`*.plan` files present in env dirs — `git rm --cached` pending.
- No TF CI / lint / policy scanning yet. Some IAM statements use `Resource = "*"`.
- Manual ACM/DNS validation step. Prod HA (replica/failover) + backup retention to confirm.
- Prod logical DB backup: on-demand `prod-db-backup` Lambda → S3 (manual, not in TF state;
  needs TF import + S3 lifecycle + schedule decision). Prod Aurora port is **3306**.

## Change log
- 2026-06-09 — WAF prod **APPLIED** (count mode), mirroring dev. Added
  `environments/prod/eu-north-1/waf.tf` (byte-identical to dev) + the `var.waf` block to prod
  `variables.tf`. `var.waf` defaults carry all config, so no tfvars needed; env differences
  resolve via `var.aws_profile` (→ web ACL `camion-prod-alb`) and prod's
  `module.backend_load_balancer`/`module.alarms_sns_topic`. Targeted apply (`-target=module.waf`
  + log group + alarm) = 5 add / 0 change / 0 destroy. Verified: ACL associated to `prod-alb`,
  default_action Allow, all 4 rules count/override-count. P2-13 now done for dev + prod;
  remaining is selective enforce (count→block) after soak.
- 2026-06-08 — Assets-CDN PAB conflict (P2-14) fixed in code. Set
  `block_origin_public_access_enabled = true` on `module.assets_cdn` in **dev + prod**
  `static-assets.tf` (the `cloudposse/cloudfront-s3-cdn` var that drives the origin PAB's
  `block_public_policy`/`restrict_public_buckets`; the OAC bucket policy doesn't depend on
  it, so no side effects). **Dev:** live bucket already all-true → plan now **clean (No
  changes)**, no apply; the WAF `-target` workaround is no longer needed. **Prod:** ⚠️ live
  bucket `prod-assets-377404936654-eu-north-1` is currently LOOSENED
  (`BlockPublicPolicy=false`/`RestrictPublicBuckets=false`); edit makes plan `0 add / 2
  change / 0 destroy` (both PABs flip false→true = tighten). **Applied to prod 2026-06-09**
  (targeted apply of the 2 PAB resources): live now all-true, re-plan clean, OAC bucket
  policy intact (delivery unaffected). Conflict resolved permanently in both envs.
- 2026-06-08 — WAF dev **APPLIED** (count mode). `terraform apply` of only the 5 WAF
  resources via `-target=module.waf -target=aws_cloudwatch_log_group.waf
  -target=aws_cloudwatch_metric_alarm.waf_rate_limit_counted[0]`. Verified: web ACL
  `camion-dev-alb` associated to `dev-alb`, default_action Allow, all 4 rules count/override
  count. **Why targeted:** a full-dir plan showed `5 add / 1 change / 0 destroy`; the extra
  change was UNRELATED drift — `module.assets_cdn.aws_s3_bucket_public_access_block.origin[0]`
  flipping `block_public_policy` + `restrict_public_buckets` true→false (a security
  regression). Root cause: two PABs on one bucket (`module.assets_bucket…s3bucket_nopublic[0]`
  all-true vs the `cloudposse/cloudfront-s3-cdn` module wanting false) ping-pong each apply.
  Excluded it; logged as fix-next under PROJECT-PLAN P2-14. ⚠️ Until P2-14 is fixed, dev
  applies must be `-target`ed or this S3 diff explicitly discarded. Also noted: `terraform
  fmt -check -recursive` is dirty across several dev files (chatbot/dashboard/frontend/iam/
  rds/static-assets/terraform.tf + tfvars) — `waf.tf` itself is clean; separate fmt pass owed.
- 2026-06-08 — Prod DB-dump Lambda (NOT Terraform-managed): created `prod-db-backup`
  Lambda (container image, `FROM postgres:17` + awslambdaric) that streams `pg_dump -Fc` of
  prod DB `app` to `s3://prod-db-backups-377404936654-eu-north-1/app/app-<UTCts>.dump`.
  Password read at runtime from the managed `rds!cluster-…` secret; role write-only +
  least-privilege; bucket SSE-KMS(`alias/s3`)/private/versioned; in VPC private subnets.
  On-demand only (no schedule). Verified: clean invoke + valid `pg_restore --list` (104
  tables). Built via CLI+Docker, tagged `managed-by=manual`, **not in TF state** (import is
  PROJECT-PLAN backlog). Spec in `specs/db-backup-lambda/`. ⚠️ prod Aurora listens on
  **port 3306**, not 5432.
- 2026-06-08 — WAF (dev, count mode): added `environments/dev/eu-north-1/waf.tf` + `var.waf`
  via `cloudposse/waf/aws` v1.17.0 on the ALB. DDoS/scraping/rate-limit rules all
  `count` (default_action allow); Bot Control toggle off. validate clean; count-mode verified.
  Applied later same day — see entry above. Spec in `specs/waf-dev-alb/`. Advances
  PROJECT-PLAN P2-13 (dev portion).
- 2026-06-03 — PROJECT INIT: analyzed full codebase; created ARCHITECTURE.md, PATTERNS.md,
  PROJECT-PLAN.md, MEMORY.md; added Claude Code handoff (CLAUDE.md, .claude/settings.local.
  json, .gitignore updates). No infrastructure changed. Awaiting review before feature work.
