# Security Groups - Creates standalone security group with configurable ingress rules

resource "aws_security_group" "main" {
  count = var.security_group_name != null ? 1 : 0

  name        = var.security_group_name
  description = var.security_group_description != null ? var.security_group_description : "Security group ${var.security_group_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.enable_ssh_access ? concat(
      [
        {
          cidr_blocks = var.ssh_allowed_cidrs
          protocol    = "tcp"
          from_port   = 22
          to_port     = 22
          description = "SSH access"
        }
      ],
      var.security_group_ingress_rules
    ) : var.security_group_ingress_rules

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description != null ? ingress.value.description : "Ingress from ${join(", ", ingress.value.cidr_blocks)} on ${ingress.value.protocol}:${ingress.value.from_port}-${ingress.value.to_port}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name = var.security_group_name
    },
    var.tags
  )
}
