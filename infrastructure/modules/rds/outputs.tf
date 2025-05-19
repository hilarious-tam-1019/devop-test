output "rds_endpoint" {
  description = "Endpoint of the RDS"
  value       = aws_db_instance.rds_instance.endpoint
}

output "rds_sg_id" {
  description = "ID of the Security Group for RDS"
  value       = aws_security_group.rds_sg.id
}
