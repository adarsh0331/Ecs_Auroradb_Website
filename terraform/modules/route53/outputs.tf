output "env_domain_name" {
  description = "Environment-specific domain name"
  value       = "${var.env}.${var.domain_name}"
}
