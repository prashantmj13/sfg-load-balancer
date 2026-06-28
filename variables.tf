variable "project_id" {
  type        = string
  description = "GCP project ID where resources are deployed."
}

variable "region" {
  type        = string
  description = "GCP region for regional load balancer resources."
}

variable "name_prefix" {
  type        = string
  description = "Short identifier prepended to every resource name. Must be lowercase alphanumeric with hyphens."
  default     = "sfg"
}

variable "network" {
  type        = string
  description = "Self-link or URL of the VPC network for the forwarding rule."
}

variable "subnetwork" {
  type        = string
  description = "Self-link or URL of the subnetwork to assign the internal forwarding rule IP."
}

variable "lb_ip_address" {
  type        = string
  description = "Static internal IP address for the forwarding rule. Leave empty to auto-assign."
  default     = ""
}

variable "instance_group_url" {
  type        = string
  description = "Self-link of the MIG instance group. Use module.sfg_asg.instance_group_url from the sfg-autoscaling module."
}

variable "sfg_port" {
  type        = number
  description = "TCP port SFG listens on. Must match the named port defined in the MIG."
  default     = 8443
}

variable "health_check_request_path" {
  type        = string
  description = "HTTPS request path for the LB health check."
  default     = "/health"
}

variable "ssl_certificate" {
  type        = string
  description = "Self-link of an existing GCP SSL certificate (self-managed or managed). Set this OR ssl_certificate_domains, not both."
  default     = ""
}

variable "ssl_certificate_domains" {
  type        = list(string)
  description = "Domain names for a GCP-managed SSL certificate. Set this OR ssl_certificate, not both."
  default     = []
}

variable "armor_allow_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed by Cloud Armor. All other traffic is denied by the default rule. CIS 3.10."
  default     = []
}

variable "armor_preview_mode" {
  type        = bool
  description = "Run Cloud Armor in preview mode (log but do not enforce). Set false in production."
  default     = false
}

variable "backend_timeout_sec" {
  type        = number
  description = "Timeout in seconds for backend service connections."
  default     = 30
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to all resources. Merged with module-managed CIS tracking labels."
  default     = {}
}
