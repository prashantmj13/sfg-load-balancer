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

variable "port" {
  type        = number
  description = "TCP port the backend instances listen on."
}
