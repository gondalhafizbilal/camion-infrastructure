# Rollback / teardown — Prod DB-dump Lambda

These resources are **not** in Terraform state; remove via CLI. Order matters only for the
bucket (must be emptied before delete). `export AWS_PROFILE=camion-prod AWS_REGION=eu-north-1`.

## Disable without deleting (safest)
```bash
# Remove any invoke triggers (none today). To fully stop use:
aws lambda put-function-concurrency --function-name prod-db-backup --reserved-concurrent-executions 0
```

## Full teardown
```bash
# 1. Lambda + log group
aws lambda delete-function --function-name prod-db-backup
aws logs delete-log-group --log-group-name /aws/lambda/prod-db-backup

# 2. IAM
aws iam delete-role-policy --role-name lambda-db-backup-role-prod --policy-name lambda-db-backup-policy-prod
aws iam detach-role-policy --role-name lambda-db-backup-role-prod \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole
aws iam delete-role --role-name lambda-db-backup-role-prod

# 3. Security group (after the Lambda's ENIs are released — may take a few minutes)
aws ec2 delete-security-group --group-id sg-0c1fbefa2cd3fea86

# 4. ECR repo (images included)
aws ecr delete-repository --repository-name prod-db-backup --force

# 5. S3 bucket — DESTRUCTIVE: deletes all backups. Empty (incl. versions) then delete.
aws s3 rm s3://prod-db-backups-377404936654-eu-north-1 --recursive
# delete remaining versions/markers if versioning produced any, then:
aws s3api delete-bucket --bucket prod-db-backups-377404936654-eu-north-1
```

## Notes
- The RDS security group was **not** modified, so nothing to revert there.
- No KMS grant was created (the `alias/s3` key policy already permits account IAM).
- Open follow-ups (see PROJECT-PLAN backlog): import these into Terraform; add an S3
  lifecycle expiry/Glacier rule; decide on a schedule.
