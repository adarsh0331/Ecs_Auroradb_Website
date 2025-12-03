# modules/aurora/main.tf

############################################
# KMS Key for Aurora Encryption
############################################
resource "aws_kms_key" "aurora" {
  description             = "KMS key for Aurora DB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = {
    Name = "${var.project_name}-aurora-kms-${var.env}"
  }
}


# --------------------------------------------
# Security Group for Aurora DB
# --------------------------------------------
resource "aws_security_group" "aurora_sg" {
  name        = "${var.project_name}-aurora-sg-${var.env}"
  description = "Allow access to Aurora DB from ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow MySQL traffic from ECS tasks"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Allow only ECS SG to access DB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-aurora-sg-${var.env}"
  }
}

# --------------------------------------------
# DB Subnet Group
# --------------------------------------------
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "${var.project_name}-db-subnet-group-${var.env}"
  subnet_ids = var.private_db_subnets
  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.env}"
  }
}

############################################
# Random Generators
############################################
# Generates a short random suffix for unique secret names
resource "random_string" "suffix" {
  length  = 4
  special = false
}

# Generates a secure random DB password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_#%!"
}


############################################
# AWS Secrets Manager for DB Credentials
############################################
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.project_name}-db-secret-${var.env}-${random_string.suffix.result}"
  description = "Aurora DB credentials"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}


# --------------------------------------------
# Aurora Cluster
# --------------------------------------------
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "${var.project_name}-aurora-cluster-${var.env}"
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  master_username         = var.db_username
  master_password         = random_password.db_password.result
  database_name           = var.db_name
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.aurora.arn
  backup_retention_period = 7
  preferred_backup_window = "04:00-05:00"
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = {
    Name        = "${var.project_name}-aurora-cluster-${var.env}"
    Environment = var.env
  }
}

# --------------------------------------------
# Aurora Cluster Instances (Writer + Reader)
# --------------------------------------------
resource "aws_rds_cluster_instance" "aurora_instances" {
  count              = 2
  identifier         = "${var.project_name}-aurora-${count.index + 1}-${var.env}"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = var.db_instance_class
  engine             = var.db_engine
  publicly_accessible = false

  tags = {
    Name = "${var.project_name}-aurora-instance-${count.index + 1}-${var.env}"
  }
}
