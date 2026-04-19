variable "openai_api_key" {
  type      = string
  sensitive = true
}

variable "csrf_secret" {
  type      = string
  sensitive = true
}

variable "jwt_private_key" {
  type      = string
  sensitive = true
}

variable "jwt_public_key" {
  type      = string
  sensitive = true
}

variable "ec2_key_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
}

variable "repo_clone_url" {
  description = "Git repository URL cloned during EC2 bootstrap"
  type        = string
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN for enabling HTTPS on ALB"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID for creating a canonical DNS record"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "Optional Route53 record name to point to the ALB (e.g. api.example.com)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment name used for resource naming and tagging"
  type        = string
  default     = "dev"
}

variable "stack_id" {
  description = "Short stable stack identifier used to make names unique across deployments"
  type        = string
  default     = "core"
}

variable "frontend_origin" {
  description = "Amplify app HTTPS origin for CORS (e.g. https://main.abc123.amplifyapp.com). Set after first Amplify deploy."
  type        = string
  default     = ""
}

variable "api_base_url" {
  description = "Backend HTTPS URL for the Amplify frontend (e.g. https://api.example.com). Set after backend is deployed."
  type        = string
  default     = "http://localhost:8000"
}

variable "github_token" {
  description = "GitHub personal access token (repo scope) for Amplify to pull the repo"
  type        = string
  sensitive   = true
  default     = ""
}

locals {
  instance_name         = "cs698-${var.environment}-app-${var.stack_id}"
  enable_https_listener = var.acm_certificate_arn != ""
  create_route53_record = var.route53_zone_id != "" && var.route53_record_name != ""
  canonical_host        = local.create_route53_record ? aws_route53_record.backend[0].fqdn : aws_lb.backend.dns_name
  canonical_scheme      = local.enable_https_listener ? "https" : "http"
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "cs698-vpc" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group ---
resource "aws_security_group" "alb_sg" {
  name   = "cs698-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name   = "cs698-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 Instance ---
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# --- IAM Role for EC2 (CloudWatch Logs access) ---
resource "aws_iam_role" "ec2_app" {
  name = "cs698-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_instance_profile" "ec2_app" {
  name = "cs698-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_app.name
}

# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "app" {
  name              = "/cs698/${var.environment}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_a.id
  key_name               = var.ec2_key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_app.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/scripts/install_docker.sh", {
    OPENAI_API_KEY   = var.openai_api_key
    CSRF_SECRET      = var.csrf_secret
    JWT_PRIVATE_KEY  = var.jwt_private_key
    JWT_PUBLIC_KEY   = var.jwt_public_key
    REPO_CLONE_URL   = var.repo_clone_url
    FRONTEND_ORIGIN  = var.frontend_origin
  })

  tags = {
    Name        = local.instance_name
    ManagedBy   = "Terraform"
    Repo        = var.repo_clone_url
    Environment = var.environment
  }
}

resource "aws_lb" "backend" {
  name               = "cs698-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "backend" {
  name        = "cs698-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/health/full"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.app_server.id
  port             = 8000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_cloudfront_distribution" "api" {
  enabled         = true
  comment         = "cs698 backend - fronts ${aws_lb.backend.dns_name}"
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  origin {
    domain_name = aws_lb.backend.dns_name
    origin_id   = "alb-backend"
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb-backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Managed-CachingDisabled: API responses must never be cached
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    # Managed-AllViewerExceptHostHeader: forward all headers/cookies/QS except Host
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_lb_listener" "https" {
  count             = local.enable_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.backend.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_route53_record" "backend" {
  count   = local.create_route53_record ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = aws_lb.backend.dns_name
    zone_id                = aws_lb.backend.zone_id
    evaluate_target_health = true
  }
}
