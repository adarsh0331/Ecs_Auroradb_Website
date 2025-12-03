variable "env" {}
variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "container_image" {
  description = "Docker image for web application"
  type        = string
}
variable "db_host" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {
  sensitive = true
}
