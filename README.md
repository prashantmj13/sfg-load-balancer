# sfg-load-balancer

Terraform module that provisions a GCP Internal TCP Load Balancer in front of a Managed Instance Group. Traffic is forwarded as-is on a specified TCP port — no SSL termination, no URL routing.

## Resources Created

| Resource | Description |
|---|---|
| `google_compute_health_check` | TCP health check that probes the configured port on each backend instance |
| `google_compute_region_backend_service` | Regional backend service (`protocol = TCP`, `INTERNAL`) grouping the MIG |
| `google_compute_forwarding_rule` | Internal forwarding rule that assigns an internal IP and forwards TCP traffic to the backend |

## Usage

```hcl
module "load_balancer" {
  source = "github.com/prashantmj13/sfg-load-balancer?ref=v1.0.0"

  project_id         = "my-project"
  region             = "us-central1"
  network            = "projects/host/global/networks/shared-vpc"
  subnetwork         = "projects/host/regions/us-central1/subnetworks/app-subnet"
  instance_group_url = module.autoscaling.instance_group_url
  port               = 5001
}

output "lb_ip" {
  value = module.load_balancer.forwarding_rule_ip
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
| instance_group_url | MIG instance group URL — use `module.autoscaling.instance_group_url` | string | — | yes |
| port | TCP port the backend instances listen on | number | — | yes |
| name_prefix | Resource name prefix | string | `"sfg"` | no |
| lb_ip_address | Static internal IP for the forwarding rule. Auto-assigned if empty | string | `""` | no |
| labels | Resource labels | map(string) | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| forwarding_rule_ip | Internal IP of the load balancer — use this as the application endpoint |
| forwarding_rule_id | Forwarding rule resource ID |
| backend_service_id | Regional TCP backend service self-link |
| health_check_id | TCP health check self-link |

## How It Works

```
Client (internal VPC)
        │
        │  TCP on var.port
        ▼
[ Forwarding Rule ]  ← internal IP in var.subnetwork
        │
        ▼
[ Regional Backend Service ]  (protocol=TCP, INTERNAL)
        │
        ▼
[ MIG instances ]  ← var.instance_group_url
```

The TCP health check probes `var.port` on each instance every 10 seconds. Instances failing 3 consecutive checks are removed from the backend until they recover.

## Wiring with sfg-autoscaling

```hcl
module "autoscaling" {
  source = "github.com/prashantmj13/sfg-autoscaling?ref=v1.0.0"
  # ...
}

module "load_balancer" {
  source = "github.com/prashantmj13/sfg-load-balancer?ref=v1.0.0"

  instance_group_url = module.autoscaling.instance_group_url  # wiring point
  port               = 5001
  # ...
}
```

## Versioning

```hcl
source = "github.com/prashantmj13/sfg-load-balancer?ref=v1.0.0"
```
