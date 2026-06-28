variable "project_id" {
  type = string
}

variable "host_project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "instance_group_url" {
  type        = string
  description = "Output from sfg-autoscaling module: instance_group_url."
}

variable "ssl_certificate" {
  type        = string
  description = "Self-link of the GCP SSL certificate to attach to the LB."
}
