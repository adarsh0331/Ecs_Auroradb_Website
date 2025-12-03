# modules/vpc/variables.tf

variable "project_name" {}
variable "env" {}
variable "vpc_cidr" {}
variable "azs" {
  type = list(string)
}
variable "public_subnets" {
  type = list(string)
}
variable "private_app_subnets" {
  type = list(string)
}
variable "private_db_subnets" {
  type = list(string)
}
