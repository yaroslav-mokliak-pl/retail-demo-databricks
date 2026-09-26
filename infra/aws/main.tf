locals {
  bucket_name = "${var.project}-databricks"
}

resource "aws_s3_bucket" "databricks" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
}
