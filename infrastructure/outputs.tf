output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.app_server.public_dns
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.postgres_db.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres_db.port
}

