# S3 Buckets - Creates two S3 buckets for cache service and Harness TI

# Main cache service S3 bucket
resource "aws_s3_bucket" "cache_service" {
  bucket = var.s3_bucket_name

  tags = merge(
    {
      Name = var.s3_bucket_name
    },
    var.tags
  )
}

# Block public access for cache service bucket (security best practice)
resource "aws_s3_bucket_public_access_block" "cache_service" {
  bucket = aws_s3_bucket.cache_service.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Harness TI bucket
resource "aws_s3_bucket" "harness_ti" {
  bucket = var.harness_ti_bucket_name

  tags = merge(
    {
      Name = var.harness_ti_bucket_name
    },
    var.tags
  )
}

# Block public access for Harness TI bucket (security best practice)
resource "aws_s3_bucket_public_access_block" "harness_ti" {
  bucket = aws_s3_bucket.harness_ti.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
