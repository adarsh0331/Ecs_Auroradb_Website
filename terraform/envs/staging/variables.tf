########################################################
# Environment Name
########################################################
variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

########################################################
# Project Name
########################################################
variable "project_name" {
  description = "Project/application name"
  type        = string
}

########################################################
# Container Image (ECR URI)
########################################################
variable "container_image" {
  description = "ECR image URI for ECS deployment"
  type        = string
}

########################################################
# Database Username
########################################################
variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

########################################################
# Database Name
########################################################
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

########################################################
# Database Password
########################################################
variable "db_password" {
  description = "Database password for Aurora cluster"
  type        = string
  sensitive   = true
}
