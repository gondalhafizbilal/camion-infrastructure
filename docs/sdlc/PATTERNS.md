# Patterns & Conventions — Camion Infrastructure

> Ground-truth conventions extracted from the codebase during PROJECT INIT (2026-06-03).
> Follow these when adding or changing infrastructure. Prefer reuse over re-derivation.

## Tooling & versions
- Terraform `>= 1.5.3`; AWS provider `>= 6.13` (lockfiles in env dirs pin 6.39/6.43/6.45).
- `mise` provides `AWS_PROFILE` per environment via `environments/<env>/mise.toml`
  (**gitignored** — not committed).
- All resources in `eu-north-1`.

## Repository structure conventions
- **Root modules** live in `environments/<env>/<region>/` and are *flat*: one `.tf` file per
  topic/service (`alb.tf`, `rds.tf`, `redis.tf`, `vpc.tf`, `iam.tf`, `ssm.tf`, `frontend.tf`,
  `chatbot.tf`, `image-service.tf`, `product-translation.tf`, `dashboard.tf`,
  `static-assets.tf`, `dashboard.tf` (CW), `ecs-alarms.tf`, `data-alarms.tf`,
  `custom-aliases.tf`).
- `terraform.tf` = required_versions + S3 backend block. `main.tf` = provider + caller
  identity. `variables.tf` = typed variable declarations. `terraform.tfvars` = values
  (**gitignored**; contains sensitive data — never commit).
- **dev and prod root modules must keep identical file names.** New service ⇒ add the same
  `<service>.tf` in both env dirs; differences belong in `terraform.tfvars`, not in resource
  code.
- **Reusable modules** live in `modules/<area>/...` with the standard trio
  `main.tf` / `variables.tf` / `outputs.tf` (RDS/VPC split resources across multiple files).

## Module usage
- Prefer **Cloud Posse** registry modules (`cloudposse/*`) and `terraform-aws-modules/*` for
  commodity resources (ECR, S3, ACM, CloudFront, RDS cluster, ElastiCache, SNS, IAM users).
- Use **in-repo modules** (`modules/ecs/*`, `modules/vpc`, `modules/load-balancer`,
  `modules/kms`, `modules/s3`, `modules/iam/general`) for opinionated, Camion-specific
  composition. Reference them by relative path (`../../../modules/...`).
- When a new pattern is needed by more than one service, **extract a module** rather than
  copy-pasting between `*.tf` files.

## Naming & tagging
- Resource names are environment-prefixed where the registry module exposes `name`
  (`dev-app-postgres`, `dev-alb`, `dev-app-valkey`). IAM policies/roles are suffixed with the
  env (`github-actions-deploy-dev`).
- Every resource gets `tags = var.common_tags`, which carries
  `{ environment, owner = "camion", managed-by = "terraform" }`.

## Secrets & configuration (critical)
- **Never** put a secret in a plain `environment` entry of a container definition or in any
  committed file. Sensitive values are:
  1. created as `aws_ssm_parameter` SecureString in `ssm.tf` (or service file), then
  2. referenced in `backend_runtime_secrets` / service `secrets` via `valueFrom = <arn>`.
- Non-sensitive, Terraform-derived values (bucket id, region, endpoints, `NODE_ENV`,
  `NODE_OPTIONS`) go in `backend_runtime_environment` as plain env vars.
- DB password is **never** stored by us — it is the Aurora-managed Secrets Manager secret
  (`manage_admin_user_password = true`), referenced as
  `${...master_user_secret[0].secret_arn}:password::`.
- `terraform.tfvars`, `*.tfvars`, `dev/*.env`, `prod/*.env`, and dev-prod comparison reports
  are gitignored because they contain resolved live secrets. Keep it that way.
- Task **exec** role gets scoped `ssm:GetParameters` on `/<env>/backend/*` and
  `secretsmanager:...rds!cluster-*`; task role gets scoped S3/KMS. Maintain least privilege.

## ECS service pattern
- One cluster + one ECR repo + one service per app. ECR: `image_tag_mutability = MUTABLE`,
  `scan_images_on_push = true`, KMS-encrypted.
- Image tag convention: `<ecr_url>:<environment>-latest`.
- Capacity strategy: `FARGATE_SPOT` weight 1 (primary), `FARGATE` as on-demand fallback.
- Tasks run in **private** subnets across all 3 AZs; ingress only from the ALB security
  group on the service port; egress all.
- Set a `health_check_grace_period_seconds` generous enough for cold starts (backend uses
  60s).

## Networking pattern
- 3-tier subnets per AZ: public (ALB/NAT), private (compute), data (DB/cache, no internet).
- Data stores always go in **data** subnets and restrict ingress to the VPC CIDR / specific
  SGs. Add VPC endpoints rather than routing AWS API traffic through NAT.

## Alarms pattern
- Add alarms by editing the declarative `alarms` variable in `terraform.tfvars` (sub-maps:
  `services.<svc>` and `data.<store>`), not by hand-writing `aws_cloudwatch_metric_alarm`.
  `ecs-alarms.tf` / `data-alarms.tf` expand each spec and resolve dimensions by namespace.
- All alarms publish to the shared SNS topic; subscriptions are declared in the `alarms.sns`
  block.

## CI/CD & deploy pattern
- App deploys use GitHub OIDC roles defined in `iam.tf`. To onboard a new service repo: add
  an `aws_iam_policy` (scoped ECR push to that repo's ECR ARN + `ecs:UpdateService`), an
  `aws_iam_role` trusting
  `repo:CamionOfficial/<repo>:environment:<env>` with `aud = sts.amazonaws.com`, and the
  attachment. Mirror in prod.
- Terraform runs are **manual and local** with the env's AWS profile. Plans should be
  reviewed before apply; do not commit `*.tfplan`/`*.plan` files.

## DNS / certificates pattern
- ACM certs use DNS validation but **do not** auto-create Route 53 records or wait for
  issuance (registrar is Hostinger). After `apply`, run the `*_acm_validation_records`
  output and add the CNAMEs in Hostinger, then re-apply once `ISSUED`.

## Style
- 2-space indentation, aligned `=` within blocks, comment blocks explaining non-obvious
  trade-offs (Spot strategy, health-check grace, serverless scaling). Keep these comments
  updated when changing the rationale.
