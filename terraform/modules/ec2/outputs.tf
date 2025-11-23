output "instance_public_ip" {
  description = "public IP"
  value       = aws_instance.app.public_ip
}

output "instance_public_dns" {
  description = "public DNS"
  value       = aws_instance.app.public_dns
}

output "instance_id" {
  description = "instance id"
  value       = aws_instance.app.id
}
