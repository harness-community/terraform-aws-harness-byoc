variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "byoc"
}

# VPC Input Variables (VPC is created externally)
variable "vpc_id" {
  description = "ID of the existing VPC where resources will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the existing VPC (used for security group rules)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs in the existing VPC (used for RDS subnet group)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks (used for RDS security group rules)"
  type        = list(string)
}

# EKS Input Variables (EKS is created externally)
variable "eks_cluster_arn" {
  description = "ARN of the existing EKS cluster (used for IAM Pod Identity)"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider (alternative to Pod Identity). If using Pod Identity, leave this null."
  type        = string
  default     = null
}

variable "eks_service_account_namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
  default     = "byoc"
}

variable "eks_service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = "runner"
}

variable "enable_pod_identity" {
  description = "Enable EKS Pod Identity for the IAM role. When true, eks_oidc_provider_arn should be null and eks_cluster_arn must be provided."
  type        = bool
  default     = true
}

# RDS Variables
variable "rds_db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "byoc"
}

variable "rds_db_username" {
  description = "Master username for RDS database"
  type        = string
  default     = "postgres"
}

variable "rds_db_password" {
  description = "Master password for RDS database. If not set, a random password will be generated"
  type        = string
  sensitive   = true
  default     = null
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.2"
}

variable "rds_family" {
  description = "PostgreSQL parameter group family"
  type        = string
  default     = "postgres17"
}

variable "rds_major_engine_version" {
  description = "PostgreSQL major engine version"
  type        = string
  default     = "17"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "rds_multi_az" {
  description = "Whether to deploy RDS as Multi-AZ"
  type        = bool
  default     = false
}

variable "rds_publicly_accessible" {
  description = "Whether RDS should be publicly accessible"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "rds_force_ssl" {
  description = "Whether to force SSL connections for RDS (rds.force_ssl parameter). Set to false to disable SSL enforcement (default: false)"
  type        = bool
  default     = false
}

variable "rds_additional_allowed_cidrs" {
  description = "Additional CIDR blocks allowed to access RDS"
  type        = list(string)
  default     = []
}

# IAM Variables
variable "iam_controller_role_name" {
  description = "Name of the IAM role for the controller"
  type        = string
  default     = "byoc-controlplane"
}

variable "build_vm_role_name" {
  description = "Name of the IAM role to be created for the build VMs"
  type        = string
  default     = "byoc-build-vm"
}

variable "existing_build_vm_role_arn" {
  description = "ARN of an existing IAM role to use for the build VMs instead of creating a new one"
  type        = string
  default     = ""
}

variable "existing_build_vm_instance_profile_arn" {
  description = "ARN of an existing IAM instance profile to use for the build VMs instead of creating a new one"
  type        = string
  default     = ""
}

# Security Group Variables
variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = "byoc"
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
  default     = null
}

variable "enable_ssh_access" {
  description = "Enable SSH access (port 22) to instances. If true, SSH will be allowed from the CIDR blocks specified in ssh_allowed_cidrs"
  type        = bool
  default     = true
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to access SSH (port 22). Only used if enable_ssh_access is true"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "security_group_ingress_rules" {
  description = "List of ingress rules for security group. Each rule maps IP/CIDR to protocol and port. To allow all ports: use protocol='-1', from_port=0, to_port=65535"
  type = list(object({
    cidr_blocks = list(string)
    protocol    = string
    from_port   = number
    to_port     = number
    description = optional(string)
  }))
  default = [
    {
      cidr_blocks = ["10.0.0.0/16"]
      protocol    = "tcp"
      from_port   = 9079
      to_port     = 9079
      description = "Allow port 9079 from VPC"
    }
  ]
}

# S3 Variables
variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "cache-service-s3-bucket"
}

variable "harness_ti_bucket_name" {
  description = "Name of the S3 bucket for Harness TI Clone"
  type        = string
  default     = "harness-ti"
}

# Harness OIDC Variables
variable "harness_account_id" {
  description = "Harness account ID for OIDC identity provider. Replace <ACCOUNT_ID> in the OIDC provider URL: https://accounts.harness.io/ng/api/oidc/account/<ACCOUNT_ID>"
  type        = string
  default     = "NzQ0MjRjYmQtNWNmMS00OT"
}

variable "harness_base_url" {
  description = "Harness base URL (domain) for OIDC identity provider. The full OIDC URL will be constructed as https://<base_url>/ng/api/oidc/account/<account_id>. Defaults to accounts.harness.io"
  type        = string
  default     = "accounts.harness.io"
}

variable "harness_oidc_thumbprint" {
  description = "SHA-1 thumbprint of the Harness OIDC provider's SSL/TLS certificate. Leave null (default) to use AWS's automatic root CA trust (recommended). Only specify if Harness uses a self-signed or less common root CA certificate. To get the thumbprint, run: echo | openssl s_client -servername accounts.harness.io -connect accounts.harness.io:443 2>/dev/null | openssl x509 -fingerprint -noout -sha1 | cut -d'=' -f2 | tr -d ':'"
  type        = string
  default     = null
}

# DataSync Variables
variable "enable_datasync_gcp_to_s3" {
  description = "Enable DataSync to sync GCP bucket (source) to S3 bucket (destination)"
  type        = bool
  default     = true
}

variable "gcp_bucket_name" {
  description = "Name of the public GCP bucket to sync from (source)"
  type        = string
  default     = "harness-ti"
}

variable "gcp_bucket_agent_arn" {
  description = "ARN of the DataSync agent for GCP bucket access. The agent must be deployed and activated before creating the location. Optional for enhanced mode transfers between GCP and S3."
  type        = string
  default     = null
}

variable "datasync_schedule_expression" {
  description = "Schedule expression for DataSync task (e.g., 'rate(1 hour)')"
  type        = string
  default     = "rate(1 hour)"
}

variable "create_datasync_log_group" {
  description = "Whether to create the CloudWatch log group for DataSync. Set to false if the log group already exists."
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "byoc"
  }
}
