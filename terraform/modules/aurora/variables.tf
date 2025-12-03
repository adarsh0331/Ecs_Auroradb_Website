# modules/aurora/variables.tf

variable "project_name" {}
variable "env" {}
variable "vpc_id" {}
variable "private_db_subnets" {
  type = list(string)
}
variable "ecs_sg_id" {
  description = "ECS Security Group ID to allow DB access"
}
variable "db_engine" {
  default = "aurora-mysql"
}
variable "db_engine_version" {
  default = "8.0.mysql_aurora.3.04.0"
}
variable "db_instance_class" {
  default = "db.t3.medium"
}
variable "db_password" {
  type    = string
  default = ""
}
variable "db_username" {
  default = "admin"
}
variable "db_name" {
  default = "appdb"
}
variable "kms_key_arn" {
  description = "KMS key ARN for Aurora encryption"
  type        = string
}



