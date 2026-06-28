output "forwarding_rule_ip" {
  description = "Internal IP address of the TCP load balancer."
  value       = google_compute_forwarding_rule.tcp.ip_address
}

output "forwarding_rule_id" {
  description = "Terraform resource ID of the forwarding rule."
  value       = google_compute_forwarding_rule.tcp.id
}

output "backend_service_id" {
  description = "Self-link of the regional TCP backend service."
  value       = google_compute_region_backend_service.tcp.id
}

output "health_check_id" {
  description = "Self-link of the TCP health check."
  value       = google_compute_health_check.tcp.id
}
