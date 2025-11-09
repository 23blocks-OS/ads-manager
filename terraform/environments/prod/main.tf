terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ads-manager-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-prod"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AI Ads Manager"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = "production"
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Database Module
module "database" {
  source = "../../modules/database"

  project_name             = var.project_name
  environment              = "production"
  private_subnet_ids       = module.networking.private_subnet_ids
  security_group_id        = module.networking.rds_security_group_id
  redis_security_group_id  = module.networking.redis_security_group_id
  instance_class           = var.database_instance_class
  database_name            = var.database_name
  database_username        = var.database_username
  database_password        = var.database_password
  redis_node_type          = var.redis_node_type
  redis_auth_token         = var.redis_auth_token
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  project_name             = var.project_name
  environment              = "production"
  aws_region               = var.aws_region
  vpc_id                   = module.networking.vpc_id
  public_subnet_ids        = module.networking.public_subnet_ids
  private_subnet_ids       = module.networking.private_subnet_ids
  alb_security_group_id    = module.networking.alb_security_group_id
  ecs_security_group_id    = module.networking.ecs_tasks_security_group_id
  certificate_arn          = var.certificate_arn
  backend_image            = var.backend_image
  frontend_image           = var.frontend_image
  backend_cpu              = var.backend_cpu
  backend_memory           = var.backend_memory
  backend_desired_count    = var.backend_desired_count
  frontend_cpu             = var.frontend_cpu
  frontend_memory          = var.frontend_memory
  frontend_desired_count   = var.frontend_desired_count

  backend_environment = [
    { name = "NODE_ENV", value = "production" },
    { name = "PORT", value = "3001" },
    { name = "DATABASE_URL", value = "postgresql://${var.database_username}:${var.database_password}@${module.database.rds_address}:5432/${var.database_name}" },
    { name = "REDIS_HOST", value = module.database.redis_endpoint },
    { name = "REDIS_PORT", value = tostring(module.database.redis_port) },
  ]

  frontend_environment = [
    { name = "NODE_ENV", value = "production" },
    { name = "NEXT_PUBLIC_API_URL", value = "https://${var.domain_name}/api/v1" },
  ]
}

# S3 Bucket for Assets
resource "aws_s3_bucket" "assets" {
  bucket = "${var.project_name}-${var.environment}-assets"

  tags = {
    Name = "${var.project_name}-assets"
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled = true
  comment = "${var.project_name} CDN"

  origin {
    domain_name = module.compute.alb_dns_name
    origin_id   = "ALB"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.domain_name]

  tags = {
    Name = "${var.project_name}-cdn"
  }
}
