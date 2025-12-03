variable "env" {
  description = "Environment (dev or staging)"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (example.com)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted zone ID of ALB"
  type        = string
}
