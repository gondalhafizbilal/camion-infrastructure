# Requirements — Prod DB-dump Lambda

## Goal
On-demand logical backup (`pg_dump`) of the **prod** Aurora PostgreSQL database `app`,
stored in S3 under a timestamped object key.

## Functional
- A Lambda function in the **prod** account (`377404936654`, `eu-north-1`) that, when
  invoked, produces a `pg_dump` of database `app` and writes it to S3.
- Object key embeds UTC date+time: `app/app-<YYYYMMDDTHHMMSSZ>.dump`.
- Credentials: master password read at runtime from the AWS-managed Secrets Manager secret
  (`rds!cluster-…`); connection user `masteruser`; database `app`.
- Dump format: `pg_dump -Fc` (custom/compressed) — restorable with `pg_restore`.

## Non-functional / constraints
- **Built without Terraform** (explicit request) — created via AWS CLI + Docker.
- No plaintext secrets anywhere (only the secret **ARN** is in env; password fetched at
  runtime). Matches repo secrets convention.
- Least-privilege IAM (write-only to the backup bucket).
- Backups encrypted at rest (SSE-KMS, reusing the account `alias/s3` key) and private.
- `pg_dump` major version ≥ server major (server is 17.7 → pg_dump 17).

## Out of scope
- Automatic scheduling (EventBridge) — on-demand only for now.
- Automated restore / cross-region replication / lifecycle expiry (see rollback.md notes).
