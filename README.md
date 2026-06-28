# sfg-load-balancer

Terraform module that provisions a GCP Internal TCP Load Balancer in front of a Managed Instance Group. Forwards one or more TCP ports to backend instances — no SSL termination, no URL routing.

## Resources Created

| Resource | Description |
|---|---|
| `google_compute_health_check` | TCP health check on the first port in `ports`. Removes unhealthy instances from the backend |
| `google_compute_region_backend_service` | Regional backend service (`protocol = TCP`, `INTERNAL`) grouping the MIG |
| `google_compute_forwarding_rule` | Internal forwarding rule assigning a single internal IP that forwards all configured ports |

## Usage

### Single port

```hcl
module "load_balancer" {
  source = "github.com/prashantmj13/sfg-load-balancer?ref=v1.0.0"

  project_id         = "my-project"
  region             = "us-central1"
  network            = "projects/host/global/networks/shared-vpc"
  subnetwork         = "projects/host/regions/us-central1/subnetworks/app-subnet"
  instance_group_url = module.autoscaling.instance_group_url
  ports              = [10011]
}
```

### Multiple ports (single LB, multiple forwarding ports)

```hcl
module "load_balancer" {
  source = "github.com/prashantmj13/sfg-load-balancer?ref=v1.0.0"

  project_id         = "my-project"
  region             = "us-central1"
  network            = "projects/host/global/networks/shared-vpc"
  subnetwork         = "projects/host/regions/us-central1/subnetworks/app-subnet"
  instance_group_url = module.autoscaling.instance_group_url
  ports              = [10011, 8089]   # 10011 = control port, 8089 = file transfer port
}

output "lb_ip" {
  value = module.load_balancer.forwarding_rule_ip
}
```

All ports share the same `lb_ip`. Clients reach port 10011 and port 8089 on the same internal IP address.

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
| ports | List of TCP ports to forward. First port is used for the health check. Max 5 ports | list(number) | — | yes |
| name_prefix | Resource name prefix | string | `"sfg"` | no |
| lb_ip_address | Static internal IP for the forwarding rule. Auto-assigned if empty | string | `""` | no |
| labels | Resource labels | map(string) | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| forwarding_rule_ip | Internal IP of the load balancer — single IP serves all configured ports |
| forwarding_rule_id | Forwarding rule resource ID |
| backend_service_id | Regional TCP backend service self-link |
| health_check_id | TCP health check self-link |

## How It Works

```
Clients (internal VPC / VPN / Interconnect)
          │
          │  TCP on any port in var.ports
          ▼
[ Forwarding Rule ]  ←── single lb_ip in var.subnetwork
          │
          ▼
[ Regional Backend Service ]  (protocol=TCP, INTERNAL)
          │
          ▼
[ MIG instances ]  ←── var.instance_group_url
```

The TCP health check probes the **first port** in `var.ports` on each instance every 10 seconds. Instances failing 3 consecutive checks are removed from the backend until they recover.

## Versioning

```hcl
source = "github.com/prashantmj13/sfg-load-balancer?ref=v1.0.0"
```
