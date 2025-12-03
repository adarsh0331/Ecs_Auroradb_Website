variable "env" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecs-aurora"
}

variable "db_password" {
  description = "Aurora DB master password"
  type        = string
  default     = "MySecurePassword123!"
}
