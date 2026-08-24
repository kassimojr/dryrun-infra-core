# ADR 004 — Estrutura multi-repositório por componente

Status: aceito · Data: 2026-08-10

## Contexto
O entregável cobre infraestrutura (Terraform) e duas aplicações Kotlin, além de uma
ferramenta de carga. Era preciso decidir entre monorepo e repos por componente.

## Decisão
7 repositórios (ver tabela em `docs/CONTRACTS.md`). Regras de fronteira:
- Infra **compartilhada e de fundação** (VPC, S3 de relatórios, SSM, CloudWatch,
  backend remoto) fica em `dryrun-infra-core` — camada 0 da ordem de apply.
- Cluster EKS fica em repo próprio (dono único, ciclo de vida distinto das apps).
- Infra **da aplicação** (IRSA, ECR, manifests K8s) fica na pasta `infra/` do repo da app.
- Gerador de carga fica separado por não ser código de produção (não é deployado).
- Integração entre stacks via `terraform_remote_state` sobre os outputs contratados.

## Consequências
- PRs e ownership claros por componente; destroy isolado sem afetar a fundação.
- Exige contrato de outputs estável (este repo) e ordem de apply documentada.
