output "tfe_url" {
  value = "https://${var.route53_subdomain}.${var.route53_zone}"
}