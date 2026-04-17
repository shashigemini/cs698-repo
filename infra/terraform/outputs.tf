output "public_ip" {
  value = aws_instance.app_server.public_ip
}

output "public_dns" {
  value = aws_instance.app_server.public_dns
}

output "backend_url" {
  value = "${local.canonical_scheme}://${local.canonical_host}"
}

output "alb_dns_name" {
  value = aws_lb.backend.dns_name
}

output "canonical_host" {
  value = local.canonical_host
}

output "instance_id" {
  value = aws_instance.app_server.id
}

output "instance_name" {
  value = local.instance_name
}
