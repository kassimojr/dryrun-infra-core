# dryrun-infra-core

Infraestrutura de fundação do desafio **Dry-Run — Processamento Lote EKS + MSK (versão SQS)**:
VPC/rede, bucket S3 de relatórios, SSM Parameter Store (regras), CloudWatch (log groups e
dashboard) e backend remoto do Terraform.

É a **camada 0**: deve ser aplicada antes de `dryrun-infra-sqs`, `dryrun-infra-msk`,
`dryrun-infra-eks` e da infra das aplicações.

## Estrutura

| Diretório | Conteúdo |
|---|---|
| [`bootstrap/`](bootstrap/) | Stack mínima do backend remoto: bucket de state `dryrun-terraform-state-<account_id>` + tabela de lock `dryrun-terraform-lock` (state local; primeiro apply) |
| [`terraform/`](terraform/) | Stack principal: VPC `dryrun-vpc`, bucket `dryrun-reports-<account_id>`, parâmetros SSM `/dryrun/*`, log groups `/dryrun/app/*` e dashboard `dryrun-main` |
| `docs/` | Contratos compartilhados (`docs/CONTRACTS.md`) e ADRs |

## Ordem de apply

1. `bootstrap/` (backend remoto — primeiro apply, state local)
2. `terraform/` (esta camada, `dryrun-infra-core`)
3. `dryrun-infra-sqs`, `dryrun-infra-msk`, `dryrun-infra-eks` (qualquer ordem)
4. `infra/` de `dryrun-app-processor` e `dryrun-app-consumer`
5. Deploy das aplicações no EKS

## Runbook (executado pelo dono da conta AWS)

Pré-requisitos: Terraform >= 1.7 e credenciais AWS da conta alvo exportadas no shell
(`AWS_PROFILE` ou variáveis `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`), região `us-east-1`.

### 1. Bootstrap (uma única vez por conta)

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
# anote os outputs: state_bucket_name, lock_table_name
```

### 2. Stack principal

```bash
cd ../terraform
cp backend.hcl.example backend.hcl
# edite backend.hcl: substitua <account_id> pelo ID da conta
# (o mesmo valor de state_bucket_name do bootstrap)

terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Variáveis têm defaults sensatos (região `us-east-1`, CIDR `10.0.0.0/16`, 2 AZs, retenção
de logs 7 dias, regras PIX/TED/DOC = `"true"`, TTL do cache = `"60"`). Para sobrescrever,
use `-var` ou um arquivo `*.tfvars`.

Os **outputs** desta stack (`vpc_id`, `private_subnet_ids`, `public_subnet_ids`,
`reports_bucket_name`, `reports_bucket_arn`, `processor_log_group_name`,
`consumer_log_group_name`) são consumidos pelos demais repos via `terraform_remote_state`
(key `dryrun-infra-core/terraform.tfstate`).

## CI

GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) roda, para as duas
stacks, `terraform fmt -check`, `terraform init -backend=false` e `terraform validate` —
sem credenciais AWS. O `apply` é sempre manual, seguindo o runbook acima.
