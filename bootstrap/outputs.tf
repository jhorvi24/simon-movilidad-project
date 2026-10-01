output "state_bucket_names" {
  description = "Nombres de los buckets de estado por ambiente. Usalos en los backend.tf de env/dev y env/prod."
  value       = { for env, b in aws_s3_bucket.tfstate : env => b.id }
}

output "state_bucket_arns" {
  description = "ARNs de los buckets de estado por ambiente."
  value       = { for env, b in aws_s3_bucket.tfstate : env => b.arn }
}
