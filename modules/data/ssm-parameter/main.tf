locals {
  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, {
    TerraformModule = local.module_label
  })
}

# WARNING: SecureString plaintext values are persisted in Terraform state.
# Use an encrypted backend with restricted access. key_id is only meaningful
# for SecureString parameters; a null key_id falls back to the AWS-managed
# default KMS alias (alias/aws/ssm).
resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = each.key
  type        = each.value.type
  value       = each.value.value
  description = each.value.description
  tier        = each.value.tier
  key_id      = each.value.key_id

  tags = merge(local.default_tags, {
    Name = each.key
  })
}
