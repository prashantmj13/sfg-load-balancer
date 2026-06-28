locals {
  resource_prefix = "${var.name_prefix}-sfg"

  common_labels = merge(var.labels, {
    managed_by    = "terraform"
    module        = "sfg-load-balancer"
    cis_compliant = "level2"
  })

  use_managed_cert    = length(var.ssl_certificate_domains) > 0 && var.ssl_certificate == ""
  ssl_certificate_url = local.use_managed_cert ? google_compute_managed_ssl_certificate.sfg[0].id : var.ssl_certificate
}
