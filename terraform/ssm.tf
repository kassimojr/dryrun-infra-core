# Regras de processamento por tipo e configuração do cache (contrato SSM).

resource "aws_ssm_parameter" "rules" {
  for_each = var.transaction_rules

  name  = "/dryrun/rules/${each.key}"
  type  = "String"
  value = each.value
}

resource "aws_ssm_parameter" "rules_cache_ttl" {
  name  = "/dryrun/config/rules-cache-ttl-seconds"
  type  = "String"
  value = var.rules_cache_ttl_seconds
}
