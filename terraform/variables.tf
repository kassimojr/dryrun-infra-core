variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR da VPC dryrun-vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs usadas pelas subnets (2 AZs)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas (uma por AZ)"
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas (uma por AZ)"
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20"]
}

variable "log_retention_days" {
  description = "Retenção (dias) dos log groups das aplicações"
  type        = number
  default     = 7
}

variable "rules_cache_ttl_seconds" {
  description = "TTL (segundos) do cache de regras no processor"
  type        = string
  default     = "60"
}

variable "transaction_rules" {
  description = "Regras por tipo de transação (habilitado = \"true\")"
  type        = map(string)
  default = {
    PIX = "true"
    TED = "true"
    DOC = "true"
  }
}
