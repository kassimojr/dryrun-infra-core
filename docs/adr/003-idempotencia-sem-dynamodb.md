# ADR 003 — Idempotência sem DynamoDB

Status: aceito · Data: 2026-08-10

## Contexto
O RF5 pede que o mesmo insumo não seja processado duas vezes. Com a entrada em fila
(ADR 001/002) não existe mais "arquivo + eTag". DynamoDB não está no desenho oficial.

## Decisão
Atender a idempotência com mecanismos nativos, sem adicionar componentes ao desenho:
1. Dedup FIFO por `MessageDeduplicationId = transaction_id` (janela de 5 min);
2. Producer Kafka idempotente (`enable.idempotence=true`, `acks=all`);
3. Relatório com chave S3 determinística `reports/<batchId>.json` (regravável).

## Consequências
- Cobre reenvio acidental, retries e duplicação do producer — os casos reais do fluxo.
- Não cobre reenvio da mesma transação após 5 min; evolução documentada: tabela
  DynamoDB (`transaction_id` PK, escrita condicional, TTL) caso dedup durável seja exigida.
