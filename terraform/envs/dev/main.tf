provider "aws" {
  region = "us-east-1"
}

# --------------------------------------------------------
# Create a KMS key for Aurora DB encryption
# --------------------------------------------------------
resource "aws_kms_key" "aurora" {
  description             = "KMS key for Aurora DB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-aurora-kms-${var.env}"
    Environment = var.env
  }
}

# --------------------------------------------------------
# VPC Module
# --------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  project_name        = var.project_name
  env                 = var.env
  vpc_cidr            = "10.0.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  private_db_subnets  = ["10.0.5.0/24", "10.0.6.0/24"]
}

# --------------------------------------------------------
# ECS Module
# --------------------------------------------------------
module "ecs" {
  source             = "../../modules/ecs"
  env                = var.env
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_app_subnet_ids
  container_image    = "nginx:latest"

  # Temporarily remove Aurora dependency to avoid circular reference
  db_host     = ""  
  db_name     = "appdb"
  db_username = "admin"
  db_password = "MySecurePassword123!"
}

# --------------------------------------------------------
# Aurora Module
# --------------------------------------------------------
module "aurora" {
  source              = "../../modules/aurora"
  project_name        = var.project_name
  env                 = var.env
  vpc_id              = module.vpc.vpc_id
  private_db_subnets  = module.vpc.private_db_subnet_ids
  ecs_sg_id           = module.ecs.ecs_sg_id
  db_password         = var.db_password
  kms_key_arn         = aws_kms_key.aurora.arn  # ✅ now valid
}

# --------------------------------------------------------
# Route53
# --------------------------------------------------------
module "route53" {
  source       = "../../modules/route53"
  env          = var.env
  domain_name  = "vijaychandra.site"
  alb_dns_name = module.ecs.alb_dns_name
  alb_zone_id  = module.ecs.alb_zone_id
}

# --------------------------------------------------------
# SNS
# --------------------------------------------------------
module "sns" {
  source      = "../../modules/sns"
  env         = var.env
  alert_email = "alerts@mydomain.com"
}

# --------------------------------------------------------
# CloudWatch
# --------------------------------------------------------
module "cloudwatch" {
  source           = "../../modules/cloudwatch"
  env              = var.env
  ecs_cluster_name = module.ecs.cluster_name
  db_cluster_id    = module.aurora.db_cluster_id
  sns_topic_arn    = module.sns.topic_arn
  aws_region       = "us-east-1"
}
