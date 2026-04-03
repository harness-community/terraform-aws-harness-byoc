# Harness VM Runner Stand-Alone Infrastructure

This Terraform module creates the necessary AWS infrastructure for the Harness VM Runner, excluding VPC and EKS which must be created separately.

The runner itself is not provisioned via this module and should be done seperatly in your hosting provider of choice:
- [ECS](https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate)
- [Helm]() (in-progress)

## Prerequisites

Before using this module, you must have:

1. **VPC** - An existing VPC with:
   - VPC ID
   - VPC CIDR block
   - Private subnet IDs
   - Private subnet CIDR blocks

2. **EKS Cluster** - An existing EKS cluster with:
   - Cluster ARN
   - OIDC provider ARN (if not using Pod Identity)

## Resources Created

This module creates the following AWS resources:

- **S3 Buckets**:
  - Harness TI bucket

- **RDS PostgreSQL**:
  - PostgreSQL database instance
  - DB subnet group
  - RDS security group

- **IAM Roles & Policies**:
  - Controller role (for EKS service account)
  - Build VM role (for EC2 instances)
  - S3 cache role (with Harness OIDC provider)
  - Instance profiles

- **Security Groups**:
  - Standalone security group (optional)
  - RDS security group

## Usage

### Basic Example

```hcl
module "byoc_infrastructure" {
  source = "./terraform-sa"

  # Project configuration
  project_name = "my-project"
  aws_region   = "us-east-1"

  # VPC configuration (from existing VPC)
  vpc_id                 = "vpc-12345678"
  vpc_cidr_block         = "10.0.0.0/16"
  private_subnet_ids     = ["subnet-12345678", "subnet-87654321", "subnet-abcdef12"]
  private_subnet_cidrs   = ["10.0.8.0/22", "10.0.12.0/22", "10.0.16.0/22"]

  # EKS configuration (from existing EKS cluster)
  eks_cluster_arn = "arn:aws:eks:us-east-1:123456789012:cluster/my-cluster"
  enable_pod_identity = true

  # S3 configuration
  s3_bucket_name       = "my-cache-service-bucket"
  harness_ti_bucket_name = "my-harness-ti-bucket"

  # Harness OIDC configuration
  harness_account_id = "YOUR_HARNESS_ACCOUNT_ID"

  # Tags
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "my-project"
  }
}
```

### Using OIDC Instead of Pod Identity

```hcl
module "byoc_infrastructure" {
  source = "./terraform-sa"

  # ... other configuration ...

  # EKS configuration with OIDC
  eks_cluster_arn        = "arn:aws:eks:us-east-1:123456789012:cluster/my-cluster"
  eks_oidc_provider_arn  = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  enable_pod_identity    = false
}
```

## Required Variables

| Name | Description | Type |
|------|-------------|------|
| vpc_id | ID of the existing VPC | string |
| vpc_cidr_block | CIDR block of the existing VPC | string |
| private_subnet_ids | List of private subnet IDs | list(string) |
| private_subnet_cidrs | List of private subnet CIDR blocks | list(string) |
| eks_cluster_arn | ARN of the existing EKS cluster | string |

## Validation

Before applying, validate the configuration:

```bash
cd terraform-sa
terraform init
terraform validate
terraform plan
```

## Notes

- VPC and EKS must be created before using this module
- The module supports both EKS Pod Identity and OIDC provider authentication
- RDS password is randomly generated if not provided
- DataSync is optional and disabled by default

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 6.0 |
| random | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | 6.37.0 |
| random | 3.8.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| rds | terraform-aws-modules/rds/aws | ~> 6.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.datasync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_datasync_location_object_storage.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/datasync_location_object_storage) | resource |
| [aws_datasync_location_s3.destination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/datasync_location_s3) | resource |
| [aws_datasync_task.sync_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/datasync_task) | resource |
| [aws_db_subnet_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_eks_pod_identity_association.cp_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_instance_profile.build_vm_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.s3_cache_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.harness](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.build_vm_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cp_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.datasync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.s3_cache_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudwatch_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cp_runner_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cp_s3_read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.datasync_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.datasync_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.s3_cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.s3_read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.cache_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.harness_ti](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.cache_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.harness_ti](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudwatch_log_group.datasync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudwatch_log_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_region | AWS region to deploy resources | `string` | `"us-east-1"` | no |
| build\_vm\_role\_name | Name of the IAM role to be created for the build VMs | `string` | `"byoc-build-vm"` | no |
| create\_datasync\_log\_group | Whether to create the CloudWatch log group for DataSync. Set to false if the log group already exists. | `bool` | `false` | no |
| datasync\_schedule\_expression | Schedule expression for DataSync task (e.g., 'rate(1 hour)') | `string` | `"rate(1 hour)"` | no |
| eks\_cluster\_arn | ARN of the existing EKS cluster (used for IAM Pod Identity) | `string` | n/a | yes |
| eks\_oidc\_provider\_arn | ARN of the EKS OIDC provider (alternative to Pod Identity). If using Pod Identity, leave this null. | `string` | `null` | no |
| eks\_service\_account\_name | Kubernetes service account name | `string` | `"runner"` | no |
| eks\_service\_account\_namespace | Kubernetes namespace for the service account | `string` | `"byoc"` | no |
| enable\_datasync\_gcp\_to\_s3 | Enable DataSync to sync GCP bucket (source) to S3 bucket (destination) | `bool` | `true` | no |
| enable\_pod\_identity | Enable EKS Pod Identity for the IAM role. When true, eks\_oidc\_provider\_arn should be null and eks\_cluster\_arn must be provided. | `bool` | `true` | no |
| enable\_ssh\_access | Enable SSH access (port 22) to instances. If true, SSH will be allowed from the CIDR blocks specified in ssh\_allowed\_cidrs | `bool` | `true` | no |
| existing\_build\_vm\_instance\_profile\_arn | ARN of an existing IAM instance profile to use for the build VMs instead of creating a new one | `string` | `""` | no |
| existing\_build\_vm\_role\_arn | ARN of an existing IAM role to use for the build VMs instead of creating a new one | `string` | `""` | no |
| gcp\_bucket\_agent\_arn | ARN of the DataSync agent for GCP bucket access. The agent must be deployed and activated before creating the location. Optional for enhanced mode transfers between GCP and S3. | `string` | `null` | no |
| gcp\_bucket\_name | Name of the public GCP bucket to sync from (source) | `string` | `"harness-ti"` | no |
| harness\_account\_id | Harness account ID for OIDC identity provider. Replace <ACCOUNT\_ID> in the OIDC provider URL: https://accounts.harness.io/ng/api/oidc/account/<ACCOUNT\_ID> | `string` | `"NzQ0MjRjYmQtNWNmMS00OT"` | no |
| harness\_base\_url | Harness base URL (domain) for OIDC identity provider. The full OIDC URL will be constructed as https://<base\_url>/ng/api/oidc/account/<account\_id>. Defaults to accounts.harness.io | `string` | `"accounts.harness.io"` | no |
| harness\_oidc\_thumbprint | SHA-1 thumbprint of the Harness OIDC provider's SSL/TLS certificate. Leave null (default) to use AWS's automatic root CA trust (recommended). Only specify if Harness uses a self-signed or less common root CA certificate. To get the thumbprint, run: echo \| openssl s\_client -servername accounts.harness.io -connect accounts.harness.io:443 2>/dev/null \| openssl x509 -fingerprint -noout -sha1 \| cut -d'=' -f2 \| tr -d ':' | `string` | `null` | no |
| harness\_ti\_bucket\_name | Name of the S3 bucket for Harness TI Clone | `string` | `"harness-ti"` | no |
| iam\_controller\_role\_name | Name of the IAM role for the controller | `string` | `"byoc-controlplane"` | no |
| private\_subnet\_cidrs | List of private subnet CIDR blocks (used for RDS security group rules) | `list(string)` | n/a | yes |
| private\_subnet\_ids | List of private subnet IDs in the existing VPC (used for RDS subnet group) | `list(string)` | n/a | yes |
| project\_name | Name of the project (used for resource naming) | `string` | `"byoc"` | no |
| rds\_additional\_allowed\_cidrs | Additional CIDR blocks allowed to access RDS | `list(string)` | `[]` | no |
| rds\_allocated\_storage | RDS allocated storage in GB | `number` | `20` | no |
| rds\_backup\_retention\_period | Number of days to retain RDS backups | `number` | `7` | no |
| rds\_db\_name | Name of the RDS database | `string` | `"byoc"` | no |
| rds\_db\_password | Master password for RDS database. If not set, a random password will be generated | `string` | `null` | no |
| rds\_db\_username | Master username for RDS database | `string` | `"postgres"` | no |
| rds\_engine\_version | PostgreSQL engine version | `string` | `"17.2"` | no |
| rds\_family | PostgreSQL parameter group family | `string` | `"postgres17"` | no |
| rds\_force\_ssl | Whether to force SSL connections for RDS (rds.force\_ssl parameter). Set to false to disable SSL enforcement (default: false) | `bool` | `false` | no |
| rds\_instance\_class | RDS instance class | `string` | `"db.t3.micro"` | no |
| rds\_major\_engine\_version | PostgreSQL major engine version | `string` | `"17"` | no |
| rds\_max\_allocated\_storage | RDS maximum allocated storage in GB | `number` | `100` | no |
| rds\_multi\_az | Whether to deploy RDS as Multi-AZ | `bool` | `false` | no |
| rds\_publicly\_accessible | Whether RDS should be publicly accessible | `bool` | `false` | no |
| s3\_bucket\_name | Name of the S3 bucket | `string` | `"cache-service-s3-bucket"` | no |
| security\_group\_description | Description of the security group | `string` | `null` | no |
| security\_group\_ingress\_rules | List of ingress rules for security group. Each rule maps IP/CIDR to protocol and port. To allow all ports: use protocol='-1', from\_port=0, to\_port=65535 | <pre>list(object({<br/>    cidr_blocks = list(string)<br/>    protocol    = string<br/>    from_port   = number<br/>    to_port     = number<br/>    description = optional(string)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_blocks": [<br/>      "10.0.0.0/16"<br/>    ],<br/>    "description": "Allow port 9079 from VPC",<br/>    "from_port": 9079,<br/>    "protocol": "tcp",<br/>    "to_port": 9079<br/>  }<br/>]</pre> | no |
| security\_group\_name | Name of the security group | `string` | `"byoc"` | no |
| ssh\_allowed\_cidrs | CIDR blocks allowed to access SSH (port 22). Only used if enable\_ssh\_access is true | `list(string)` | <pre>[<br/>  "10.0.0.0/16"<br/>]</pre> | no |
| tags | A map of tags to assign to all resources | `map(string)` | <pre>{<br/>  "Environment": "dev",<br/>  "ManagedBy": "terraform",<br/>  "Project": "byoc"<br/>}</pre> | no |
| vpc\_cidr\_block | CIDR block of the existing VPC (used for security group rules) | `string` | n/a | yes |
| vpc\_id | ID of the existing VPC where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| datasync\_role\_arn | ARN of the DataSync IAM role |
| datasync\_task\_arn | ARN of the DataSync task |
| harness\_oidc\_provider\_arn | ARN of the Harness OIDC identity provider |
| harness\_oidc\_provider\_url | URL of the Harness OIDC identity provider |
| iam\_build\_vm\_instance\_profile\_arn | ARN of the IAM build VM instance profile |
| iam\_build\_vm\_instance\_profile\_name | Name of the IAM build VM instance profile |
| iam\_controller\_role\_arn | ARN of the IAM controller role |
| iam\_controller\_role\_name | Name of the IAM controller role |
| rds\_db\_name | RDS database name |
| rds\_db\_password | RDS database password (stored in Terraform state) |
| rds\_db\_username | RDS database username |
| rds\_instance\_address | RDS instance address |
| rds\_instance\_endpoint | RDS instance endpoint |
| rds\_instance\_id | RDS instance ID |
| rds\_instance\_port | RDS instance port |
| s3\_bucket\_arn | ARN of the S3 bucket |
| s3\_bucket\_name | Name of the S3 bucket |
| s3\_cache\_instance\_profile\_arn | ARN of the S3 cache IAM instance profile |
| s3\_cache\_instance\_profile\_name | Name of the S3 cache IAM instance profile |
| s3\_cache\_role\_arn | ARN of the S3 cache IAM role |
| s3\_cache\_role\_id | ID of the S3 cache IAM role |
| s3\_cache\_role\_name | Name of the S3 cache IAM role |
| s3\_harness\_ti\_clone\_bucket\_arn | ARN of the harness-ti-clone S3 bucket |
| s3\_harness\_ti\_clone\_bucket\_name | Name of the harness-ti-clone S3 bucket |
| security\_group\_arn | ARN of the security group |
| security\_group\_id | ID of the security group |
| security\_group\_name | Name of the security group |
