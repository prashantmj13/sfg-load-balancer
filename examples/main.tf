provider "google" {
  project = var.project_id
  region  = var.region
}

module "sfg_lb" {
  source = "github.com/prashantmj13/sfg-load-balancer?ref=v1.0.0"

  project_id         = var.project_id
  region             = var.region
  network            = "projects/${var.host_project_id}/global/networks/shared-vpc"
  subnetwork         = "projects/${var.host_project_id}/regions/${var.region}/subnetworks/app-subnet"
  instance_group_url = var.instance_group_url
  port               = var.port

  labels = {
    env  = "production"
    team = "platform"
  }
}

output "lb_ip" {
  value = module.sfg_lb.forwarding_rule_ip
}
