
output "id" {
  value = aws_s3_bucket.s3bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.s3bucket.arn
}

output "bucket_domain_name" {
  value = aws_s3_bucket.s3bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.s3bucket.bucket_regional_domain_name
}
