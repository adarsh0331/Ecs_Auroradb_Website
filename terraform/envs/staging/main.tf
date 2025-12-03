#############################################
# AWS Provider (Staging)
#############################################
provider "aws" {
  region = "us-east-1"
}

#############################################
# KMS Key for Aurora Encryption (STAGING)
#############################################
resource "aws_kms_key" "aurora" {
  description             = "KMS key for Aurora DB encryption (STAGING)"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-aurora-kms-${var.env}"
    Environment = var.env
  }
}


#############################################
# VPC for STAGING (Independent)
#############################################
module "vpc" {
  source = "../../modules/vpc"

  project_name        = var.project_name
  env                 = var.env

  vpc_cidr            = "10.20.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b"]

  public_subnets      = ["10.20.1.0/24", "10.20.2.0/24"]
  private_app_subnets = ["10.20.3.0/24", "10.20.4.0/24"]
  private_db_subnets  = ["10.20.5.0/24", "10.20.6.0/24"]
}

#############################################
# ECS Cluster + Application (STAGING)
#############################################
module "ecs" {
  source = "../../modules/ecs"

  env                = var.env
  container_image    = var.container_image

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_app_subnet_ids

  db_host     = module.aurora.aurora_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}


#############################################
# Aurora MySQL Cluster (STAGING)
#############################################
module "aurora" {
  source             = "../../modules/aurora"
  project_name       = var.project_name
  env                = var.env

  vpc_id             = module.vpc.vpc_id
  private_db_subnets = module.vpc.private_db_subnet_ids

  ecs_sg_id          = module.ecs.ecs_sg_id
  db_password        = var.db_password
  kms_key_arn        = aws_kms_key.aurora.arn
}

#############################################
# Route53 - Create record for STAGING ALB
#############################################
module "route53" {
  source      = "../../modules/route53"

  env         = var.env
  domain_name = "vijaychandra.site"

  # ALB data from ECS module
  alb_dns_name = module.ecs.alb_dns_name
  alb_zone_id  = module.ecs.alb_zone_id
}

#############################################
# SNS Alerts (STAGING)
#############################################
module "sns" {
  source      = "../../modules/sns"
  env         = var.env
  alert_email = "alerts@mydomain.com"
}

#############################################
# CloudWatch Alarms (STAGING)
#############################################
module "cloudwatch" {
  source           = "../../modules/cloudwatch"

  env              = var.env
  ecs_cluster_name = module.ecs.cluster_name
  db_cluster_id    = module.aurora.db_cluster_id
  sns_topic_arn    = module.sns.topic_arn
  aws_region       = "us-east-1"
}
