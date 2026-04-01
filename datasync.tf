# DataSync - Syncs GCP bucket (source) to S3 bucket (destination)

# IAM Role for DataSync
resource "aws_iam_role" "datasync" {
  count = var.enable_datasync_gcp_to_s3 ? 1 : 0
  name  = "harness-ti-gcp-to-s3-sync-datasync-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for DataSync S3 access (destination - write permissions)
resource "aws_iam_role_policy" "datasync_s3" {
  count = var.enable_datasync_gcp_to_s3 ? 1 : 0
  name  = "harness-ti-gcp-to-s3-sync-datasync-s3-policy"
  role  = aws_iam_role.datasync[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          aws_s3_bucket.harness_ti.arn,
          "${aws_s3_bucket.harness_ti.arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for DataSync CloudWatch Logs
resource "aws_iam_role_policy" "datasync_logs" {
  count = var.enable_datasync_gcp_to_s3 ? 1 : 0
  name  = "harness-ti-gcp-to-s3-sync-datasync-logs-policy"
  role  = aws_iam_role.datasync[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# DataSync GCP Location (Source - public bucket, no credentials needed)
# Note: For enhanced mode transfers between GCP and S3, an agent may not be required.
# However, if using basic mode or if an agent is preferred, provide the agent ARN.
# For public buckets, access_key and secret_key are omitted.
resource "aws_datasync_location_object_storage" "source" {
  count      = var.enable_datasync_gcp_to_s3 ? 1 : 0
  agent_arns = var.gcp_bucket_agent_arn != null ? [var.gcp_bucket_agent_arn] : []

  server_hostname = "storage.googleapis.com"
  server_protocol = "HTTPS"
  server_port     = 443

  bucket_name = var.gcp_bucket_name

  # Public bucket - credentials are omitted for public access
  # access_key and secret_key are optional and not needed for public buckets

  tags = var.tags
}

# DataSync S3 Location (Destination)
resource "aws_datasync_location_s3" "destination" {
  count         = var.enable_datasync_gcp_to_s3 ? 1 : 0
  s3_bucket_arn = aws_s3_bucket.harness_ti.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync[0].arn
  }

  tags = var.tags
}

# CloudWatch Log Group for DataSync task logs
# For Enhanced mode tasks, the log group name must be exactly /aws/datasync
# Reference existing log group
data "aws_cloudwatch_log_group" "datasync" {
  count = var.enable_datasync_gcp_to_s3 && !var.create_datasync_log_group ? 1 : 0
  name  = "/aws/datasync"
}

# Create the log group only if create_datasync_log_group is true
# By default, assumes the log group already exists and uses the data source above
resource "aws_cloudwatch_log_group" "datasync" {
  count             = var.enable_datasync_gcp_to_s3 && var.create_datasync_log_group ? 1 : 0
  name              = "/aws/datasync"
  retention_in_days = 7

  tags = var.tags
}

# DataSync Task with built-in scheduling
resource "aws_datasync_task" "sync_task" {
  count                    = var.enable_datasync_gcp_to_s3 ? 1 : 0
  name                     = "harness-ti-gcp-to-s3-sync"
  source_location_arn      = aws_datasync_location_object_storage.source[0].arn
  destination_location_arn = aws_datasync_location_s3.destination[0].arn
  task_mode                = "ENHANCED" # Required for agentless object storage transfers

  # Use existing log group from data source (default), or created resource if create_datasync_log_group is true
  cloudwatch_log_group_arn = var.create_datasync_log_group ? aws_cloudwatch_log_group.datasync[0].arn : data.aws_cloudwatch_log_group.datasync[0].arn

  schedule {
    schedule_expression = var.datasync_schedule_expression
  }

  options {
    verify_mode                    = "ONLY_FILES_TRANSFERRED" # Recommended for Enhanced mode
    overwrite_mode                 = "ALWAYS"
    atime                          = "BEST_EFFORT"
    mtime                          = "PRESERVE"
    uid                            = "NONE"
    gid                            = "NONE"
    preserve_deleted_files         = "REMOVE"
    preserve_devices               = "NONE"
    posix_permissions              = "NONE"
    bytes_per_second               = -1
    task_queueing                  = "ENABLED"
    log_level                      = "TRANSFER"
    transfer_mode                  = "CHANGED"
    security_descriptor_copy_flags = "NONE"
    object_tags                    = "NONE"
  }

  tags = var.tags
}
