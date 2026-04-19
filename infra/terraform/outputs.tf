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

output "amplify_app_url" {
  description = "Default Amplify app URL — set this as CORS origin in backend and update frontend_origin variable"
  value       = "https://main.${aws_amplify_app.frontend.default_domain}"
}

output "cloudfront_url" {
  description = "HTTPS CloudFront URL fronting the ALB backend"
  value       = "https://${aws_cloudfront_distribution.api.domain_name}"
}

output "amplify_webhook_url" {
  description = "Set this as AMPLIFY_PROD_WEBHOOK_URL GitHub secret to enable deploy-aws-amplify.yml"
  value       = aws_amplify_webhook.main.url
  sensitive   = true
}
