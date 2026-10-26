# Design — Prod DB-dump Lambda

## Overview
A container-image Lambda runs `pg_dump -Fc` against the prod Aurora cluster and streams the
output straight into an S3 multipart upload. Built and deployed entirely via AWS CLI +
Docker (no Terraform).

## Why a container image
The Lambda managed runtimes ship no Postgres client. `pg_dump` must be **major ≥ 17** to
dump the 17.7 server. The image is `FROM postgres:17-bookworm` (guarantees a matching
`pg_dump`) plus the AWS Lambda Runtime Interface Client (`awslambdaric`) + `boto3`.

## Networking
- Lambda runs in `vpc-0231ae0ba788b8003` **private** subnets
  (`subnet-0ae537a850f64ec8d`, `subnet-0b6790be357847bbc`, `subnet-0bafe0225d6d688cc`).
- Private subnets route `0.0.0.0/0 → NAT` → reaches **Secrets Manager** (no SM VPC endpoint
  exists). S3 traffic uses the VPC **S3 gateway endpoint**. `10.20.0.0/16 → local` reaches
  the DB.
- DB SG (`sg-0f0295a4b65fac3a6`) already allows all traffic from the VPC CIDR
  `10.20.0.0/16`, so the Lambda's own SG (`sg-0c1fbefa2cd3fea86`, egress-all) needs **no**
  change to the RDS SG.

## DB connection facts (resolved live)
| Item | Value |
|---|---|
| Endpoint | `prod-app-postgres.cluster-cti8mkis6zft.eu-north-1.rds.amazonaws.com` |
| **Port** | **3306** (the cluster genuinely listens on 3306, not 5432) |
| DB / user | `app` / `masteruser` |
| Secret ARN | `…:secret:rds!cluster-47545648-547c-4325-97ab-f4d9697ca98a-erlrm4` (AWS-managed `aws/secretsmanager` key) |

## Streaming
`handler.py` wraps `pg_dump`'s stdout pipe in a byte-counting reader and hands it to
`s3.upload_fileobj` → streaming multipart upload. Nothing is buffered to `/tmp`, so the
10 GB ephemeral limit is not a factor; size is reported from the counter (no `s3:GetObject`
needed → role stays write-only).

## IAM (`lambda-db-backup-role-prod`)
- Managed `AWSLambdaVPCAccessExecutionRole` (ENI + CloudWatch Logs).
- Inline `lambda-db-backup-policy-prod`:
  - `secretsmanager:GetSecretValue` on the cluster secret ARN.
  - `s3:PutObject` on `arn:aws:s3:::prod-db-backups-377404936654-eu-north-1/*`.
  - `kms:GenerateDataKey`,`kms:Decrypt`,`kms:DescribeKey` on the `alias/s3` key.
- No KMS grant needed: the `alias/s3` key policy has `EnableIAMUserPermissions`
  (account-root `kms:*`), so the inline IAM suffices. The secret uses the AWS-managed key,
  so `GetSecretValue` covers decrypt.

## Resource inventory (all tagged `managed-by=manual`)
| Resource | Name / id |
|---|---|
| ECR repo | `prod-db-backup` (image tag in use: `:2`) |
| Lambda | `prod-db-backup` (image, x86_64, 1024 MB, 900 s timeout) |
| Exec role | `lambda-db-backup-role-prod` |
| Inline policy | `lambda-db-backup-policy-prod` |
| Security group | `sg-0c1fbefa2cd3fea86` (`prod-db-backup-lambda-sg`) |
| S3 bucket | `prod-db-backups-377404936654-eu-north-1` (SSE-KMS, private, versioned) |
| Log group | `/aws/lambda/prod-db-backup` (30-day retention) |

## Known limits
- **15-min Lambda cap.** Current full dump ≈ 70 MiB in well under a minute, so ample
  headroom. If the DB grows enough to exceed ~15 min, move the same image to ECS Fargate /
  AWS Batch `run-task` (no time cap) — the image and handler are reusable as-is.
- Not in Terraform state (intentional). See PROJECT-PLAN backlog for the import follow-up.
