# sfg-load-balancer

Terraform module for deploying a CIS Level 2-compliant internal HTTPS load balancer for IBM Sterling File Gateway (SFG) on GCP.

## Features

- Internal HTTPS load balancer (INTERNAL_SELF_MANAGED / Envoy-based)
- TLS 1.2 minimum with RESTRICTED cipher profile (CIS 3.9)
- Cloud Armor WAF with default-deny policy and OWASP XSS rule (CIS 3.10)
- Backend request logging at 100% sample rate (CIS 3.11)
- Supports both self-managed and GCP-managed SSL certificates
- Designed to consume the `instance_group_url` output from `sfg-autoscaling`

## Usage

```hcl
module "sfg_lb" {
  source = "github.com/org/sfg-load-balancer?ref=v1.0.0"

  project_id         = "my-project"
  region             = "us-central1"
  network            = "projects/host/global/networks/shared-vpc"
  subnetwork         = "projects/host/regions/us-central1/subnetworks/app-subnet"
  instance_group_url = module.sfg_asg.instance_group_url
  ssl_certificate    = "projects/my-project/global/sslCertificates/sfg-cert"
  armor_allow_ip_ranges = ["10.0.0.0/8"]
}

output "sfg_endpoint" {
  value = module.sfg_lb.forwarding_rule_ip
}
```

## Combined Usage (with sfg-autoscaling)

```hcl
module "sfg_asg" {
  source = "github.com/org/sfg-autoscaling?ref=v1.0.0"
  # ... autoscaling variables
}

module "sfg_lb" {
  source = "github.com/org/sfg-load-balancer?ref=v1.0.0"

  instance_group_url = module.sfg_asg.instance_group_url  # wiring point
  # ... other variables
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.0 |
| google provider | >= 5.0.0, < 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| project_id | GCP project ID | string | — | yes |
| region | GCP region | string | — | yes |
| network | VPC network self-link | string | — | yes |
| subnetwork | Subnetwork self-link | string | — | yes |
| instance_group_url | MIG instance group URL from sfg-autoscaling | string | — | yes |
| ssl_certificate | Existing SSL certificate self-link | string | "" | one of these two |
| ssl_certificate_domains | Domains for GCP-managed SSL certificate | list(string) | [] | one of these two |
| name_prefix | Resource name prefix | string | "sfg" | no |
| lb_ip_address | Static internal IP for forwarding rule | string | "" | no |
| sfg_port | SFG application port | number | 8443 | no |
| health_check_request_path | Health check HTTP path | string | "/health" | no |
| armor_allow_ip_ranges | CIDRs allowed by Cloud Armor | list(string) | [] | no |
| armor_preview_mode | Run Cloud Armor in preview (log only) mode | bool | false | no |
| backend_timeout_sec | Backend service timeout in seconds | number | 30 | no |
| labels | Additional resource labels | map(string) | {} | no |

## Outputs

| Name | Description |
|---|---|
| forwarding_rule_ip | Internal VIP — the SFG endpoint for consumers |
| forwarding_rule_id | Forwarding rule resource ID |
| backend_service_id | Backend service self-link |
| ssl_policy_id | SSL policy self-link |
| security_policy_id | Cloud Armor security policy self-link |
| health_check_id | LB health check self-link |
| ssl_certificate_id | SSL certificate in use |

## CIS Level 2 Controls

| CIS Benchmark | Control | Implementation |
|---|---|---|
| 3.9 | TLS 1.2 minimum | `ssl_policy.min_tls_version = TLS_1_2` |
| 3.9 | Restricted cipher profile | `ssl_policy.profile = RESTRICTED` |
| 3.10 | Cloud Armor WAF | Default-deny security policy with OWASP XSS rule |
| 3.11 | Backend request logging | `log_config { enable=true, sample_rate=1.0 }` |

## SSL Certificate Options

**Option A — Existing certificate (self-managed or pre-created managed):**
```hcl
ssl_certificate = "projects/my-project/global/sslCertificates/sfg-cert"
```

**Option B — GCP-managed certificate (auto-provisioned and renewed):**
```hcl
ssl_certificate_domains = ["sfg.internal.example.com"]
```

Only one option should be set per deployment.

## Cloud Armor Policy

The default policy is **deny-all** at the lowest priority. Supply `armor_allow_ip_ranges` to permit traffic from approved CIDRs. An OWASP XSS pre-configured rule is always enabled at priority 900.

Set `armor_preview_mode = true` during initial rollout to observe traffic patterns without blocking, then switch to `false` for enforcement.

## Versioning

Pin to a tag in the `source` URL:

```hcl
source = "github.com/org/sfg-load-balancer?ref=v1.0.0"
```

Run `terraform init -upgrade` after bumping the ref.
