# ADR 002 — Uma transação por mensagem, fila FIFO

Status: aceito · Data: 2026-08-10

## Contexto
Mensagens SQS têm limite de 256 KB; um "arquivo JSON" não cabe em uma mensagem.
Era preciso decidir a granularidade: 1 transação por mensagem, lote de N, ou ponteiro
para objeto externo (que reintroduziria S3 na entrada, contrariando a orientação).

## Decisão
- 1 transação JSON (snake_case) por mensagem, enviadas com `SendMessageBatch` (10).
- Fila FIFO em modo high throughput: `MessageGroupId = customer_id` (ordem por cliente),
  `MessageDeduplicationId = transaction_id` (dedup nativa, janela 5 min).
- `batchId` como message attribute preserva a fronteira do "arquivo" para o relatório.

## Consequências
- Falha isolada: só a transação problemática vai à DLQ.
- Paralelismo por escala de pods, sem particionamento de arquivo.
- Throughput exigido (167 tx/s) fica muito abaixo do limite do FIFO high throughput.
- Custo de chamadas mitigado por batch de 10 (Send/Delete/Receive).
