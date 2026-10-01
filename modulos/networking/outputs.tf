output "vpc_id" {
  description = "ID de la VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subnets publicas (para el ALB)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas (para las tareas ECS)."
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "ID del security group del ALB."
  value       = aws_security_group.alb.id
}

output "tasks_security_group_id" {
  description = "ID del security group de las tareas ECS."
  value       = aws_security_group.tasks.id
}
