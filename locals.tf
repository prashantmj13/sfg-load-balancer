locals {
  resource_prefix = "${var.name_prefix}-sfg"

  common_labels = merge(var.labels, {
    managed_by = "terraform"
    module     = "sfg-load-balancer"
  })
}
