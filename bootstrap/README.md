# bootstrap — backend remoto do Terraform

Stack mínima e separada que cria os recursos usados **exclusivamente** pelo backend
do Terraform (não fazem parte da arquitetura da aplicação):

- Bucket S3 `dryrun-terraform-state-<account_id>` (versionado, criptografado, acesso
  público bloqueado)
- Tabela DynamoDB `dryrun-terraform-lock` (lock do state)

## Por que backend local?

Este é o **primeiro apply** da conta: os recursos do backend remoto ainda não existem,
então esta stack usa state local (arquivo `terraform.tfstate` neste diretório).
Guarde esse arquivo com cuidado (ou importe os recursos depois, se necessário) —
ele só muda se o bootstrap mudar.

## Runbook

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

Anote os outputs (`state_bucket_name`, `lock_table_name`): eles são usados no
`backend.hcl` das demais stacks (ver README na raiz).
