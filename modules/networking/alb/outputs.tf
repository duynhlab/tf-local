output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the Application Load Balancer."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group."
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (null when no certificate_arn)."
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "security_group_ids" {
  description = "Security group IDs associated with the load balancer (echo of input)."
  value       = var.security_group_ids
}
