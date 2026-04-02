# IAM - Creates IAM roles with EC2 and OIDC/Pod Identity trust relationships

locals {
  # Extract OIDC ID from ARN if provided
  # ARN format: arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDC_ID
  # Split ARN by "/" to get: ["arn:aws:iam::ACCOUNT_ID:oidc-provider", "oidc.eks.REGION.amazonaws.com", "id", "OIDC_ID"]
  oidc_arn_parts     = var.eks_oidc_provider_arn != null ? split("/", var.eks_oidc_provider_arn) : []
  oidc_id            = length(local.oidc_arn_parts) > 0 ? local.oidc_arn_parts[length(local.oidc_arn_parts) - 1] : null
  oidc_provider_url  = var.eks_oidc_provider_arn != null && local.oidc_id != null ? "oidc.eks.${var.aws_region}.amazonaws.com/id/${local.oidc_id}" : null
  build_vm_role_name = var.existing_build_vm_role_arn != "" ? split("/", var.existing_build_vm_role_arn)[1] : var.build_vm_role_name
}

# Controller IAM Role
resource "aws_iam_role" "cp_role" {
  count = var.iam_controller_role_name != null ? 1 : 0
  name  = var.iam_controller_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # OIDC trust relationship (if OIDC provider ARN is provided)
      var.eks_oidc_provider_arn != null ? [
        {
          Effect = "Allow"
          Principal = {
            Federated = var.eks_oidc_provider_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${local.oidc_provider_url}:sub" = "system:serviceaccount:${var.eks_service_account_namespace}:${var.eks_service_account_name}"
              "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
            }
          }
        }
      ] : [],
      # Pod identity trust relationship (if enable_pod_identity is true)
      var.enable_pod_identity != null ? [
        {
          Effect = "Allow"
          Principal = {
            Service = "pods.eks.amazonaws.com"
          }
          Action = [
            "sts:AssumeRole",
            "sts:TagSession"
          ]
          Condition = {
            StringEquals = {
              "aws:RequestTag/eks-cluster-arn"            = var.eks_cluster_arn
              "aws:RequestTag/kubernetes-namespace"       = var.eks_service_account_namespace
              "aws:RequestTag/kubernetes-service-account" = var.eks_service_account_name
            }
          }
        }
      ] : []
    )
  })

  tags = var.tags
}

# Attach custom EC2 permissions policy to the controller role
resource "aws_iam_role_policy" "cp_runner_policy" {
  count = var.iam_controller_role_name != null ? 1 : 0
  name  = "${var.iam_controller_role_name}-cp-runner-policy"
  role  = aws_iam_role.cp_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RunnerSecretsAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "elasticache:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "RunnerInstanceLifecycle"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:RebootInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:GetConsoleOutput"
        ]
        Resource = "*"
      },
      {
        Sid    = "RunnerStorageManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      },
      {
        Sid    = "RunnerNetworkingAndSecurity"
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
        ]
        Resource = "*"
      },
      {
        Sid    = "RunnerTaggingResources"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "RunnerGeneralReadAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeRegions",
          "ec2:DescribeImages",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeTags",
        ]
        Resource = "*"
      },
      {
        Sid    = "RunnerIAMPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = var.existing_build_vm_role_arn != "" ? var.existing_build_vm_role_arn : aws_iam_role.build_vm_role[0].arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Add S3 read access policy for controller role
resource "aws_iam_role_policy" "cp_s3_read_policy" {
  count = var.iam_controller_role_name != null ? 1 : 0
  name  = "${var.iam_controller_role_name}-s3-read-policy"
  role  = aws_iam_role.cp_role[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.harness_ti.arn,
          "${aws_s3_bucket.harness_ti.arn}/*"
        ]
      }
    ]
  })
}

# EKS Pod Identity Association
resource "aws_eks_pod_identity_association" "cp_role" {
  count           = var.enable_pod_identity && var.iam_controller_role_name != null ? 1 : 0
  cluster_name    = split("/", var.eks_cluster_arn)[1]
  namespace       = var.eks_service_account_namespace
  service_account = var.eks_service_account_name
  role_arn        = aws_iam_role.cp_role[0].arn
}

# Build VM IAM Role
resource "aws_iam_role" "build_vm_role" {
  count = var.existing_build_vm_role_arn == "" ? 1 : 0
  name  = local.build_vm_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# S3 read access policy for build VM role
resource "aws_iam_role_policy" "s3_read_policy" {
  count = var.existing_build_vm_role_arn == "" ? 1 : 0
  name  = "${var.build_vm_role_name}-s3-read-policy"
  role  = local.build_vm_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.harness_ti.arn,
          "${aws_s3_bucket.harness_ti.arn}/*"
        ]
      }
    ]
  })

  depends_on = [aws_iam_role.build_vm_role]
}

# CloudWatch Logs policy for build VM role
resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  count = var.existing_build_vm_role_arn == "" ? 1 : 0
  name  = "${var.build_vm_role_name}-cloudwatch-logs-policy"
  role  = local.build_vm_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/byoc/*"
      }
    ]
  })

  depends_on = [aws_iam_role.build_vm_role]
}

resource "aws_iam_role_policy_attachment" "build_vm_role_policies" {
  for_each   = toset(var.build_vm_role_policies)
  role       = aws_iam_role.build_vm_role[0].name
  policy_arn = each.value
}

# Instance profile for build VM role
resource "aws_iam_instance_profile" "build_vm_role" {
  count = var.existing_build_vm_instance_profile_arn == "" ? 1 : 0
  name  = local.build_vm_role_name
  role  = local.build_vm_role_name

  tags = var.tags

  depends_on = [aws_iam_role.build_vm_role]
}
