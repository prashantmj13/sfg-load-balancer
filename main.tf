# ── Optional Managed SSL Certificate ─────────────────────────────────────────

resource "google_compute_managed_ssl_certificate" "sfg" {
  count   = local.use_managed_cert ? 1 : 0
  project = var.project_id
  name    = "${local.resource_prefix}-managed-cert"

  managed {
    domains = var.ssl_certificate_domains
  }
}

# ── SSL Policy ────────────────────────────────────────────────────────────────

resource "google_compute_ssl_policy" "sfg" {
  project         = var.project_id
  name            = "${local.resource_prefix}-ssl-policy"
  min_tls_version = "TLS_1_2"     # CIS 3.9: disable TLS 1.0 and TLS 1.1
  profile         = "RESTRICTED"  # CIS 3.9: removes RC4, 3DES, NULL, and export ciphers
}

# ── LB Health Check ───────────────────────────────────────────────────────────
# Separate from the autoscaling module's internal health check.
# This one governs traffic routing; the other governs instance replacement.

resource "google_compute_health_check" "sfg_lb" {
  project             = var.project_id
  name                = "${local.resource_prefix}-hc-lb"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  https_health_check {
    port         = var.sfg_port
    request_path = var.health_check_request_path
  }
}

# ── Cloud Armor Security Policy ───────────────────────────────────────────────

resource "google_compute_security_policy" "sfg" {
  project = var.project_id
  name    = "${local.resource_prefix}-armor"

  # Default deny-all at lowest priority (highest integer = lowest priority in Cloud Armor)
  rule {
    action      = "deny(403)"
    priority    = 2147483647
    description = "Default deny all — CIS 3.10: default-deny WAF policy"
    preview     = var.armor_preview_mode

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  # Allow approved CIDR ranges (only created when ranges are supplied)
  dynamic "rule" {
    for_each = length(var.armor_allow_ip_ranges) > 0 ? [var.armor_allow_ip_ranges] : []
    content {
      action      = "allow"
      priority    = 1000
      description = "Allow approved IP ranges"
      preview     = var.armor_preview_mode

      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = rule.value
        }
      }
    }
  }

  # OWASP Top 10 XSS protection using GCP pre-configured rule
  rule {
    action      = "deny(403)"
    priority    = 900
    description = "Block XSS — OWASP Top 10 pre-configured rule"
    preview     = var.armor_preview_mode

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
  }
}

# ── Backend Service ───────────────────────────────────────────────────────────

resource "google_compute_backend_service" "sfg" {
  project               = var.project_id
  name                  = "${local.resource_prefix}-backend"
  protocol              = "HTTPS"
  port_name             = "sfg-https"
  timeout_sec           = var.backend_timeout_sec
  load_balancing_scheme = "INTERNAL_SELF_MANAGED"

  health_checks   = [google_compute_health_check.sfg_lb.id]
  security_policy = google_compute_security_policy.sfg.id

  backend {
    group           = var.instance_group_url
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  # CIS 3.11: backend request logging at 100% sample rate
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# ── URL Map ───────────────────────────────────────────────────────────────────

resource "google_compute_url_map" "sfg" {
  project         = var.project_id
  name            = "${local.resource_prefix}-url-map"
  default_service = google_compute_backend_service.sfg.id
}

# ── Target HTTPS Proxy ────────────────────────────────────────────────────────

resource "google_compute_target_https_proxy" "sfg" {
  project          = var.project_id
  name             = "${local.resource_prefix}-https-proxy"
  url_map          = google_compute_url_map.sfg.id
  ssl_certificates = [local.ssl_certificate_url]
  ssl_policy       = google_compute_ssl_policy.sfg.id # CIS 3.9: attach policy to proxy
}

# ── Forwarding Rule (Internal HTTPS LB) ──────────────────────────────────────

resource "google_compute_forwarding_rule" "sfg" {
  project               = var.project_id
  region                = var.region
  name                  = "${local.resource_prefix}-fwd-rule"
  load_balancing_scheme = "INTERNAL_SELF_MANAGED"
  target                = google_compute_target_https_proxy.sfg.id
  network               = var.network
  subnetwork            = var.subnetwork
  ip_address            = var.lb_ip_address != "" ? var.lb_ip_address : null
  port_range            = "443"
  labels                = local.common_labels
}
