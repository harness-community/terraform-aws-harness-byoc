# S3 Cache Role - Creates IAM role for S3 cache access with Harness OIDC identity provider

locals {
  harness_oidc_url = "https://${var.harness_base_url}/ng/api/oidc/account/${var.harness_account_id}"
}

# Create OIDC Identity Provider for Harness
resource "aws_iam_openid_connect_provider" "harness" {
  url = local.harness_oidc_url

  # Audience (client_id_list) - The audience claim in the JWT token must match this value
  # "sts.amazonaws.com" is the standard audience for AWS STS AssumeRoleWithWebIdentity
  client_id_list = [
    "sts.amazonaws.com"
  ]

  # As of July 2024, AWS trusts widely-used root CAs automatically
  # Only specify thumbprint if using self-signed or less common root CA certificates
  # If thumbprint is not provided, AWS will use the default trusted root CA
  thumbprint_list = var.harness_oidc_thumbprint != null ? [var.harness_oidc_thumbprint] : []

  tags = merge(
    {
      Name = "harness-oidc-provider"
    },
    var.tags
  )
}

# Create IAM Role for S3 Cache Access
resource "aws_iam_role" "s3_cache_role" {
  name = "s3-cache-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.harness.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.harness_base_url}/ng/api/oidc/account/${var.harness_account_id}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Attach S3 permissions policy to the role
resource "aws_iam_role_policy" "s3_cache_policy" {
  name = "s3-cache-role-s3-cache-policy"
  role = aws_iam_role.s3_cache_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3CacheBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.cache_service.arn,
          "${aws_s3_bucket.cache_service.arn}/*"
        ]
      },
      {
        Sid      = "AllowDescribeRegions"
        Effect   = "Allow"
        Action   = "ec2:DescribeRegions"
        Resource = "*"
      }
    ]
  })
}

# Create instance profile for EC2 instances
resource "aws_iam_instance_profile" "s3_cache_role" {
  name = "s3-cache-role-instance-profile"
  role = aws_iam_role.s3_cache_role.name

  tags = var.tags
}
