output "databricks_bucket_name" {
  value = aws_s3_bucket.databricks.bucket
}

output "databricks_bucket_arn" {
  value = aws_s3_bucket.databricks.arn
}