# ── TCP Health Check ──────────────────────────────────────────────────────────
# Health check uses the first port in the list (primary control port).

resource "google_compute_health_check" "tcp" {
  project             = var.project_id
  name                = "${local.resource_prefix}-hc"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = var.ports[0]
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
# Forwards all ports in var.ports to the backend service on the same port.

resource "google_compute_forwarding_rule" "tcp" {
  project               = var.project_id
  region                = var.region
  name                  = "${local.resource_prefix}-fwd-rule"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.tcp.id
  protocol              = "TCP"
  ports                 = [for p in var.ports : tostring(p)]
  network               = var.network
  subnetwork            = var.subnetwork
  ip_address            = var.lb_ip_address != "" ? var.lb_ip_address : null
  labels                = local.common_labels
}
