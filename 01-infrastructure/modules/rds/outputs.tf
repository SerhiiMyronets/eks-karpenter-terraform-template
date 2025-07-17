output "db_credential_arns" {
  value = [
    try(aws_ssm_parameter.db_password["default"].arn, null),
    try(aws_ssm_parameter.db_host["default"].arn, null),
    try(aws_ssm_parameter.db_username["default"].arn, null)
  ]
  description = "ARNs of SSM parameters for DB credentials"
}