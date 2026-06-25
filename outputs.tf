output "ec2_public_ip" {
  description = "Public IP of the EC2 instance — use this to hit the API"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2.public_dns
}

output "api_base_url" {
  description = "Base URL for the Think Cricket API"
  value       = "http://${module.ec2.public_ip}:${var.app_port}"
}

output "instance_id" {
  description = "EC2 instance ID — use for SSM Session Manager console access"
  value       = module.ec2.instance_id
}
