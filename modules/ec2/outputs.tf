output "public_ip" {
  value = aws_eip.app.public_ip
}

output "public_dns" {
  value = aws_eip.app.public_dns
}

output "instance_id" {
  value = aws_instance.app.id
}
