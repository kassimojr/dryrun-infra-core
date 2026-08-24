# CONTRACTS — Dry-Run Processamento Lote EKS + MSK (versão SQS)

Contratos compartilhados entre todos os repositórios. Qualquer mudança aqui exige PR
neste repo e atualização coordenada nos repos afetados.

## Repositórios

| Repo | Responsabilidade |
|---|---|
| `dryrun-infra-core` | VPC/rede, S3 de relatórios, SSM Parameter Store, CloudWatch (log groups + dashboard), backend remoto do Terraform |
| `dryrun-infra-sqs` | Filas SQS + DLQs + alarme >1000 → SNS |
| `dryrun-infra-msk` | Cluster MSK + tópico |
| `dryrun-infra-eks` | Cluster EKS compartilhado (node groups, OIDC, add-ons) |
| `dryrun-app-processor` | App Kotlin: SQS → validação/regras/transformação → MSK; rejeitados → fila. Pasta `infra/`: IRSA, ECR, manifests K8s |
| `dryrun-app-consumer` | App Kotlin: MSK → consolidação por batchId → relatório S3. Pasta `infra/`: IRSA, ECR, manifests K8s |
| `dryrun-load-generator` | Gerador de mensagens JSON + scripts de teste de performance |

## Convenções gerais

- Região: `us-east-1` · 1 conta AWS · prefixo de recursos: `dryrun`
- Tags obrigatórias em todo recurso: `Project=dryrun`, `ManagedBy=terraform`, `Repo=<nome do repo>`
- Terraform >= 1.7, provider `hashicorp/aws ~> 5.0`
- Backend remoto: bucket S3 `dryrun-terraform-state-<account_id>` + lock DynamoDB `dryrun-terraform-lock`
  (criados por bootstrap documentado no `dryrun-infra-core`); key = `<repo>/terraform.tfstate`
- Comunicação entre stacks: `terraform_remote_state` lendo os **outputs** listados abaixo
- Ordem de `apply`: `infra-core` → (`infra-sqs`, `infra-msk`, `infra-eks` em qualquer ordem) → `infra/` dos apps → deploy K8s
- Kotlin: JDK 21, Gradle Kotlin DSL, ktlint; CI GitHub Actions (build + test + lint; infra: fmt + validate + plan sem credenciais via `-backend=false`)

## Filas SQS (dryrun-infra-sqs)

| Recurso | Nome | Configuração |
|---|---|---|
| Entrada | `dryrun-transactions-in.fifo` | FIFO, high throughput; visibility timeout 900s; long polling 20s; redrive maxReceiveCount=3 |
| DLQ entrada | `dryrun-transactions-in-dlq.fifo` | retenção 14 dias |
| Rejeitados | `dryrun-rejected` | standard; visibility timeout 300s; long polling 20s; redrive maxReceiveCount=3 |
| DLQ rejeitados | `dryrun-rejected-dlq` | retenção 14 dias |
| Alarme | `dryrun-transactions-in-depth` | `ApproximateNumberOfMessagesVisible > 1000` (5×60s) → SNS `dryrun-alerts` |

Outputs Terraform: `transactions_in_queue_url`, `transactions_in_queue_arn`, `transactions_in_dlq_arn`, `rejected_queue_url`, `rejected_queue_arn`, `rejected_dlq_arn`, `alerts_topic_arn`.

## Mensagem de entrada (origem → fila FIFO)

- 1 transação por mensagem; envio em `SendMessageBatch` (10)
- `MessageGroupId` = `customer_id` · `MessageDeduplicationId` = `transaction_id`
- Message attributes: `batchId` (String), `schemaVersion` (String, `"1"`)
- Corpo (JSON, **snake_case** — preserva a transformação do RF1):

```json
{
  "transaction_id": "tx_001",
  "transaction_type": "PIX",
  "amount": 150.50,
  "timestamp": "2024-01-15T10:30:00Z",
  "customer_id": "cust_123",
  "metadata": {"channel": "mobile"}
}
```

Validação (RF2): rejeitar se `amount < 0` ou qualquer campo obrigatório
(`transaction_id`, `transaction_type`, `amount`, `timestamp`, `customer_id`) ausente/nulo.
`metadata` é opcional.

## Mensagem de rejeição (processor → dryrun-rejected)

```json
{
  "transaction": { ...corpo original... },
  "batchId": "batch-2026-08-10-001",
  "reason": "NEGATIVE_AMOUNT | MISSING_FIELD | RULE_DISABLED | MALFORMED_JSON",
  "detail": "amount = -10.5",
  "rejectedAt": "2026-08-10T12:00:00Z"
}
```

## SSM Parameter Store (dryrun-infra-core)

| Parâmetro | Tipo | Exemplo | Uso |
|---|---|---|---|
| `/dryrun/rules/PIX` | String `"true"/"false"` | `"true"` | habilita processamento do tipo |
| `/dryrun/rules/TED` | String | `"true"` | idem |
| `/dryrun/rules/DOC` | String | `"true"` | idem |
| `/dryrun/config/rules-cache-ttl-seconds` | String | `"60"` | TTL do cache no processor |

Tipo sem parâmetro correspondente ⇒ tratado como desabilitado (`RULE_DISABLED`).

## Evento MSK (dryrun-infra-msk / processor → consumer)

- Tópico: `transactions.processed` · partitions 6 · replication 2 · key = `customerId`
- Producer: `enable.idempotence=true`, `acks=all`
- Corpo (JSON, **camelCase**, RNF2 + RF3):

```json
{
  "transactionId": "tx_001",
  "transactionType": "PIX",
  "amount": 150.50,
  "timestamp": "2024-01-15T10:30:00Z",
  "customerId": "cust_123",
  "metadata": {"channel": "mobile"},
  "processedAt": "2026-08-10T12:00:00Z",
  "classification": "credito",
  "batchId": "batch-2026-08-10-001",
  "schemaVersion": "1"
}
```

Classificação (RF3): `PIX`/`TED`/`DOC` recebidos = `credito` quando `amount >= 0`
(valores negativos nunca chegam aqui — são rejeitados). O campo existe para permitir
regra futura por tipo; a regra vigente é documentada no processor.

## Relatório consolidado (consumer → S3, dryrun-infra-core)

- Bucket: `dryrun-reports-<account_id>` · chave determinística: `reports/<batchId>.json`
  (regravável ⇒ idempotente)
- Janela de consolidação: o consumer agrega continuamente e regrava o relatório do
  `batchId` a cada flush (30s ou 1000 eventos)

```json
{
  "batchId": "batch-2026-08-10-001",
  "generatedAt": "2026-08-10T12:05:00Z",
  "totalsByType": {"PIX": {"count": 120, "totalAmount": 18500.00, "avgAmount": 154.17}},
  "totalProcessed": 300,
  "totalAmount": 55000.00,
  "avgAmount": 183.33
}
```

## Idempotência (RF5, adaptado a filas)

1. Dedup FIFO: `MessageDeduplicationId = transaction_id` (janela de 5 min) cobre reenvio/retry;
2. Producer Kafka idempotente (sem duplicata por retry do producer);
3. Relatório com chave determinística por `batchId` (regravar = mesmo resultado).

## Observabilidade

- Log groups (infra-core): `/dryrun/app/processor`, `/dryrun/app/consumer`
- Logs estruturados JSON (RNF4): campos `timestamp`, `level`, `service`, `batchId`, `transactionId`, `message`
- Métricas EMF, namespace `Dryrun`: `MessagesProcessed`, `MessagesRejected`, `MessagesFailed`,
  `MessageProcessingTimeMs`, `BatchProcessingTimeMs` (por `batchId` — desafio extra 3),
  `CircuitBreakerState`, `ReportsWritten`
- Circuit breaker (desafio extra 4): Resilience4j no processor; abre com taxa de erro > 15%
  (janela 100 chamadas) e pausa o polling da fila enquanto aberto
- Dashboard (infra-core): profundidade das filas + DLQs, throughput, erros, latência, estado do circuit breaker

## IAM / IRSA

| Service account (ns `dryrun`) | Permissões |
|---|---|
| `processor` | consume `dryrun-transactions-in.fifo`; send `dryrun-rejected`; `ssm:GetParameter*` em `/dryrun/*`; MSK write no tópico; CloudWatch Logs/PutMetricData |
| `consumer` | MSK read no tópico; `s3:PutObject` em `dryrun-reports-*/reports/*`; CloudWatch Logs/PutMetricData |
