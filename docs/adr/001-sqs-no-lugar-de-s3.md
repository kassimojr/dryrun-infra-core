# ADR 001 — Filas SQS no lugar dos buckets S3 de entrada e descarte

Status: aceito · Data: 2026-08-10

## Contexto
O desenho original usava S3 para a entrada (arquivo CSV) e para os dados rejeitados.
Por orientação do criador do desafio, os itens 1 e 4 do desenho foram substituídos por
filas SQS com DLQ, retry e timeout, e a entrada passou de CSV para JSON.

## Decisão
- Entrada: fila SQS FIFO `dryrun-transactions-in.fifo` + DLQ.
- Rejeitados: fila SQS standard `dryrun-rejected` + DLQ.
- Retry via redrive policy (`maxReceiveCount = 3`), visibility timeout 900s (entrada),
  long polling 20s, DLQs com retenção de 14 dias.
- S3 permanece apenas na saída (relatórios consolidados).

## Consequências
- O processor passa a consumir mensagens em vez de ler arquivo (paralelismo natural,
  falha isolada por mensagem).
- O limite de 256 KB por mensagem impõe a granularidade definida no ADR 002.
- O alarme de fila > 1000 mensagens (desafio extra 2) passa a fazer parte do núcleo.
