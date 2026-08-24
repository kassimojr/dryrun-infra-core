output "state_bucket_name" {
  description = "Nome do bucket S3 do state remoto"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "Nome da tabela DynamoDB de lock do Terraform"
  value       = aws_dynamodb_table.terraform_lock.name
}
