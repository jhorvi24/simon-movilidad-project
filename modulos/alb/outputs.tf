output "alb_arn" {
  description = "ARN del Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS publico del ALB. Es la URL por la que se accede a la app."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Zone ID del ALB (util para registros Route53 alias)."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN del target group al que el servicio ECS registra sus tareas."
  value       = aws_lb_target_group.this.arn
}

output "http_listener_arn" {
  description = "ARN del listener HTTP."
  value       = aws_lb_listener.http.arn
}
