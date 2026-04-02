# RDS - Creates PostgreSQL RDS instance with subnet group and security group

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    {
      Name = "${var.project_name}-rds-subnet-group"
    },
    var.tags
  )
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-postgres-sg"
  description = "Security group for RDS ${var.project_name}-postgres"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = concat(var.private_subnet_cidrs, var.rds_additional_allowed_cidrs)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.project_name}-postgres-sg"
    },
    var.tags
  )
}

# Random password for RDS (if not provided)
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# RDS PostgreSQL Instance
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.project_name}-postgres"

  engine               = "postgres"
  engine_version       = var.rds_engine_version
  family               = var.rds_family
  major_engine_version = var.rds_major_engine_version

  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"

  db_name  = var.rds_db_name
  username = var.rds_db_username
  password = var.rds_db_password != null ? var.rds_db_password : random_password.db_password.result

  manage_master_user_password = false

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Create parameter group with our custom SSL setting
  create_db_parameter_group = true
  parameters = [
    {
      name  = "rds.force_ssl"
      value = var.rds_force_ssl ? "1" : "0"
    }
  ]

  multi_az                = var.rds_multi_az
  publicly_accessible     = var.rds_publicly_accessible
  skip_final_snapshot     = true
  backup_retention_period = var.rds_backup_retention_period

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = false

  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  monitoring_interval                   = 0
  create_monitoring_role                = false
  monitoring_role_name                  = "${var.project_name}-rds-monitoring"

  tags = var.tags
}
