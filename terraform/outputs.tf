output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.instance_public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2.instance_public_dns
}

output "instance_id" {
  description = "EC2 instance id"
  value       = module.ec2.instance_id
}
