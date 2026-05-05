output "api_gateway_url" {
  description = "Base invoke URL for the API Gateway fronting the services."
  value       = "https://${aws_api_gateway_rest_api.gateway.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.gateway.stage_name}"
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance running the API container."
  value       = aws_instance.app.public_ip
}

output "direct_match_service_url" {
  description = "Direct EC2 URL for the match service API."
  value       = "http://${aws_instance.app.public_ip}:3000"
}

output "direct_analytics_service_url" {
  description = "Direct EC2 URL for the analytics service API."
  value       = "http://${aws_instance.app.public_ip}:3001"
}

output "db_endpoint" {
  description = "RDS PostgreSQL endpoint hostname used as DB_HOST."
  value       = aws_db_instance.postgres.address
}
