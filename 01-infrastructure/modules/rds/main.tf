locals {
  identifier = "${var.cluster_name}-db"
}

resource "aws_db_subnet_group" "this" {
  for_each   = var.enabled ? { default = true } : {}
  name       = "${local.identifier}-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${local.identifier}-subnet-group"
  }
}

resource "random_password" "db_password" {
  for_each = var.enabled ? { default = true } : {}
  length   = 16
  special  = true

  override_special = "!#$%^&*()-_+=<>?~"
}

resource "aws_db_instance" "this" {
  for_each               = var.enabled ? { default = true } : {}
  identifier             = local.identifier
  db_name                = var.rds_config.db_name
  username               = var.rds_config.db_username
  password               = random_password.db_password["default"].result
  engine                 = var.rds_config.engine
  engine_version         = var.rds_config.engine_version
  instance_class         = var.rds_config.instance_class
  allocated_storage      = var.rds_config.allocated_storage
  db_subnet_group_name   = aws_db_subnet_group.this["default"].name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.this["default"].id]

  tags = {
    Name = local.identifier
  }
}

resource "aws_security_group" "this" {
  for_each    = var.enabled ? { default = true } : {}
  name        = "${local.identifier}-sg"
  description = "Allow DB access from allowed sources"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.identifier}-sg"
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each          = var.enabled ? { default = true } : {}
  type              = "ingress"
  from_port         = var.rds_config.port
  to_port           = var.rds_config.port
  protocol          = "tcp"
  security_group_id = aws_security_group.this["default"].id
  cidr_blocks       = var.private_subnet_cidrs
}

resource "aws_security_group_rule" "egress_all" {
  for_each          = var.enabled ? { default = true } : {}
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this["default"].id
}

resource "aws_ssm_parameter" "db_password" {
  for_each = var.enabled ? { default = true } : {}
  name     = "/${local.identifier}/db-password"
  type     = "SecureString"
  value    = random_password.db_password["default"].result
}

resource "aws_ssm_parameter" "db_username" {
  for_each = var.enabled ? { default = true } : {}
  name     = "/${local.identifier}/db-username"
  type     = "String"
  value    = var.rds_config.db_username
}

resource "aws_ssm_parameter" "db_host" {
  for_each = var.enabled ? { default = true } : {}
  name     = "/${local.identifier}/db-host"
  type     = "String"
  value    = aws_db_instance.this["default"].address
}