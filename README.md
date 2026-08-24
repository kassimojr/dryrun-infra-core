# dryrun-infra-core

Infraestrutura de fundação do desafio **Dry-Run — Processamento Lote EKS + MSK (versão SQS)**:
VPC/rede, bucket S3 de relatórios, SSM Parameter Store (regras), CloudWatch (log groups e
dashboard) e backend remoto do Terraform.

É a **camada 0**: deve ser aplicada antes de `dryrun-infra-sqs`, `dryrun-infra-msk`,
`dryrun-infra-eks` e da infra das aplicações.

## Documentação

- [`docs/CONTRACTS.md`](docs/CONTRACTS.md) — contratos compartilhados entre todos os repos
  (nomes de recursos, schemas de mensagens/eventos/relatório, outputs, IAM, observabilidade).
- [`docs/adr/`](docs/adr/) — decisões de arquitetura (SQS no lugar de S3, granularidade
  de mensagem, idempotência sem DynamoDB, estrutura multi-repo).

## Ordem de apply

1. Bootstrap do backend (bucket de state + tabela de lock) — documentado aqui quando o
   Terraform for adicionado.
2. `dryrun-infra-core`
3. `dryrun-infra-sqs`, `dryrun-infra-msk`, `dryrun-infra-eks` (qualquer ordem)
4. `infra/` de `dryrun-app-processor` e `dryrun-app-consumer`
5. Deploy das aplicações no EKS

> O `terraform apply` é executado pelo dono da conta AWS seguindo o runbook; o CI deste
> repo roda apenas `fmt`/`validate`/`plan` sem credenciais.
