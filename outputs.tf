output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance running the API container."
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Public URL for the match service API."
  value       = "http://${aws_instance.app.public_ip}:3000"
}

output "analytics_url" {
  description = "Public URL for the analytics service API."
  value       = "http://${aws_instance.app.public_ip}:3001"
}

output "db_endpoint" {
  description = "RDS PostgreSQL endpoint hostname used as DB_HOST."
  value       = aws_db_instance.postgres.address
}
