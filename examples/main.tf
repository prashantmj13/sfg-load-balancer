provider "google" {
  project = var.project_id
  region  = var.region
}

# Assumes sfg-autoscaling module has already been applied and its outputs are known.
# In a combined root module, wire the output directly:
#   instance_group_url = module.sfg_asg.instance_group_url

module "sfg_lb" {
  source = "github.com/org/sfg-load-balancer?ref=v1.0.0"

  project_id  = var.project_id
  region      = var.region
  name_prefix = "myapp"

  network    = "projects/${var.host_project_id}/global/networks/shared-vpc"
  subnetwork = "projects/${var.host_project_id}/regions/${var.region}/subnetworks/app-subnet"

  instance_group_url = var.instance_group_url

  # Option A: Use an existing SSL certificate
  ssl_certificate = var.ssl_certificate

  # Option B: Let GCP provision a managed certificate (comment out ssl_certificate above)
  # ssl_certificate_domains = ["sfg.internal.example.com"]

  armor_allow_ip_ranges = ["10.0.0.0/8"]
  armor_preview_mode    = false

  labels = {
    env  = "production"
    team = "platform"
  }
}

output "sfg_endpoint" {
  description = "Internal IP address of the SFG load balancer."
  value       = module.sfg_lb.forwarding_rule_ip
}
