output "public_ip" {
  value = aws_instance.app_server.public_ip
}

output "public_dns" {
  value = aws_instance.app_server.public_dns
}

output "backend_url" {
  value = "http://${aws_instance.app_server.public_dns}:8000"
}

output "instance_id" {
  value = aws_instance.app_server.id
}

output "instance_name" {
  value = local.instance_name
}
