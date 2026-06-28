variable "project_id" {
  type        = string
  description = "GCP project ID where resources are deployed."
}

variable "region" {
  type        = string
  description = "GCP region for the internal TCP load balancer."
}

variable "name_prefix" {
  type        = string
  description = "Short identifier prepended to every resource name."
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
  description = "Self-link of the MIG instance group. Use module.autoscaling.instance_group_url."
}

variable "ports" {
  type        = list(number)
  description = "One or more TCP ports to forward to backend instances. The first port is also used for the health check. GCP allows up to 5 ports per forwarding rule."
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to all resources."
  default     = {}
}
