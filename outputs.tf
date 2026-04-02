# RDS Outputs
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_identifier
}

output "rds_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_instance_address" {
  description = "RDS instance address"
  value       = module.rds.db_instance_address
}

output "rds_instance_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "rds_db_name" {
  description = "RDS database name"
  value       = var.rds_db_name
}

output "rds_db_username" {
  description = "RDS database username"
  value       = var.rds_db_username
  sensitive   = true
}

output "rds_db_password" {
  description = "RDS database password (stored in Terraform state)"
  value       = var.rds_db_password != null ? var.rds_db_password : random_password.db_password.result
  sensitive   = true
}

# IAM Outputs
output "iam_controller_role_arn" {
  description = "ARN of the IAM controller role"
  value       = var.iam_controller_role_name != null ? aws_iam_role.cp_role[0].arn : null
}

output "iam_controller_role_name" {
  description = "Name of the IAM controller role"
  value       = var.iam_controller_role_name != null ? aws_iam_role.cp_role[0].name : null
}

output "iam_controller_policy_arns" {
  description = "ARNs of the IAM controller policies"
  value       = var.iam_controller_role_name != null || var.create_policies ? [aws_iam_policy.cp_runner_policy[0].arn, aws_iam_policy.cp_s3_read_policy[0].arn] : null
}

output "iam_build_vm_instance_profile_name" {
  description = "Name of the IAM build VM instance profile"
  value       = var.existing_build_vm_instance_profile_arn == "" ? aws_iam_instance_profile.build_vm_role[0].name : null
}

output "iam_build_vm_instance_profile_arn" {
  description = "ARN of the IAM build VM instance profile"
  value       = var.existing_build_vm_instance_profile_arn == "" ? aws_iam_instance_profile.build_vm_role[0].arn : null
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the security group"
  value       = var.security_group_name != null ? aws_security_group.main[0].id : null
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = var.security_group_name != null ? aws_security_group.main[0].arn : null
}

output "security_group_name" {
  description = "Name of the security group"
  value       = var.security_group_name != null ? aws_security_group.main[0].name : null
}

# S3 Harness TI Clone Outputs
output "s3_harness_ti_clone_bucket_arn" {
  description = "ARN of the harness-ti-clone S3 bucket"
  value       = aws_s3_bucket.harness_ti.arn
}

output "s3_harness_ti_clone_bucket_name" {
  description = "Name of the harness-ti-clone S3 bucket"
  value       = aws_s3_bucket.harness_ti.bucket
}
