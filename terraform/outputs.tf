output "vpc_id" {
  description = "ID da VPC dryrun-vpc"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "reports_bucket_name" {
  description = "Nome do bucket S3 de relatórios"
  value       = aws_s3_bucket.reports.bucket
}

output "reports_bucket_arn" {
  description = "ARN do bucket S3 de relatórios"
  value       = aws_s3_bucket.reports.arn
}

output "processor_log_group_name" {
  description = "Nome do log group do processor"
  value       = aws_cloudwatch_log_group.processor.name
}

output "consumer_log_group_name" {
  description = "Nome do log group do consumer"
  value       = aws_cloudwatch_log_group.consumer.name
}
