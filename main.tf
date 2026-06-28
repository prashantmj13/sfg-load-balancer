# ── TCP Health Check ──────────────────────────────────────────────────────────

resource "google_compute_health_check" "tcp" {
  project             = var.project_id
  name                = "${local.resource_prefix}-hc"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = var.port
  }
}

# ── Regional Backend Service (TCP) ────────────────────────────────────────────

resource "google_compute_region_backend_service" "tcp" {
  project               = var.project_id
  region                = var.region
  name                  = "${local.resource_prefix}-backend"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"

  health_checks = [google_compute_health_check.tcp.id]

  backend {
    group = var.instance_group_url
  }
}

# ── Internal TCP Forwarding Rule ──────────────────────────────────────────────

resource "google_compute_forwarding_rule" "tcp" {
  project               = var.project_id
  region                = var.region
  name                  = "${local.resource_prefix}-fwd-rule"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.tcp.id
  protocol              = "TCP"
  ports                 = [tostring(var.port)]
  network               = var.network
  subnetwork            = var.subnetwork
  ip_address            = var.lb_ip_address != "" ? var.lb_ip_address : null
  labels                = local.common_labels
}
