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
