# Log groups das aplicações e dashboard principal de observabilidade.

resource "aws_cloudwatch_log_group" "processor" {
  name              = "/dryrun/app/processor"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/dryrun/app/consumer"
  retention_in_days = var.log_retention_days
}

# Dashboard dryrun-main: métricas EMF (namespace Dryrun) e profundidade das
# filas SQS. As filas vivem no repo dryrun-infra-sqs; aqui referenciamos apenas
# os nomes definidos no contrato.
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "dryrun-main"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Profundidade das filas"
          region = var.aws_region
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "dryrun-transactions-in.fifo"],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "dryrun-rejected"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Profundidade das DLQs"
          region = var.aws_region
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "dryrun-transactions-in-dlq.fifo"],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "dryrun-rejected-dlq"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Throughput (processadas / rejeitadas / falhas)"
          region = var.aws_region
          stat   = "Sum"
          period = 60
          metrics = [
            ["Dryrun", "MessagesProcessed"],
            ["Dryrun", "MessagesRejected"],
            ["Dryrun", "MessagesFailed"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Latência de processamento (ms)"
          region = var.aws_region
          stat   = "Average"
          period = 60
          metrics = [
            ["Dryrun", "MessageProcessingTimeMs"],
            ["Dryrun", "BatchProcessingTimeMs"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Circuit breaker (0=fechado, 1=aberto)"
          region = var.aws_region
          stat   = "Maximum"
          period = 60
          metrics = [
            ["Dryrun", "CircuitBreakerState"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Relatórios gravados no S3"
          region = var.aws_region
          stat   = "Sum"
          period = 60
          metrics = [
            ["Dryrun", "ReportsWritten"]
          ]
        }
      }
    ]
  })
}
