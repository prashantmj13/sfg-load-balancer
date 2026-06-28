output "forwarding_rule_ip" {
  description = "Internal IP address of the load balancer. Use this as the SFG endpoint for consumers."
  value       = google_compute_forwarding_rule.sfg.ip_address
}

output "forwarding_rule_id" {
  description = "Terraform resource ID of the forwarding rule."
  value       = google_compute_forwarding_rule.sfg.id
}

output "backend_service_id" {
  description = "Self-link of the backend service."
  value       = google_compute_backend_service.sfg.id
}

output "ssl_policy_id" {
  description = "Self-link of the SSL policy (TLS 1.2+, RESTRICTED profile)."
  value       = google_compute_ssl_policy.sfg.id
}

output "security_policy_id" {
  description = "Self-link of the Cloud Armor security policy."
  value       = google_compute_security_policy.sfg.id
}

output "health_check_id" {
  description = "Self-link of the LB-facing health check."
  value       = google_compute_health_check.sfg_lb.id
}

output "ssl_certificate_id" {
  description = "Self-link of the SSL certificate in use (managed or self-managed)."
  value       = local.ssl_certificate_url
}
