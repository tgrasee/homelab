# Homelab - Automated Infrastructure & Monitoring Stack

> Fully automated homelab built on a Dell OptiPlex with Ubiquiti networking.
> Proxmox is provisioned via answer file, configured with Ansible, VMs are
> managed with Terraform, and the monitoring stack (Grafana + Prometheus + Loki)
> is deployed via Docker Compose.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                 Dell OptiPlex (Host)                │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │              Proxmox VE 8.x                 │   │
│   │                                             │   │
│   │  ┌──────────────┐   ┌──────────────────┐    │   │
│   │  │  monitoring  │   │  (future VMs)    │    │   │
│   │  │     VM       │   │                  │    │   │
│   │  │  ┌────────┐  │   └──────────────────┘    │   │
│   │  │  │Grafana │  │                           │   │
│   │  │  │Promeths│  │                           │   │
│   │  │  │  Loki  │  │                           │   │
│   │  │  └────────┘  │                           │   │
│   │  └──────────────┘                           │   │
│   └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
            │
            │ (managed via)
            ▼
┌─────────────────────────┐
│   Ubiquiti UniFi Stack  │
│  Router / Switch / AP   │
│  VLANs + Firewall Rules │
└─────────────────────────┘
```

---

## Stack

| Layer | Tool | Purpose |
|---|---|---|
| Hypervisor | Proxmox VE 8 | Bare metal virtualization |
| Bare metal provisioning | Proxmox Answer File | Unattended OS install |
| Configuration management | Ansible | Post-install config & app deployment |
| Infrastructure as Code | Terraform | VM/LXC lifecycle management |
| Containerization | Docker + Compose | App packaging |
| Metrics | Prometheus | Time-series metrics collection |
| Logging | Loki + Promtail | Log aggregation |
| Visualization | Grafana | Dashboards & alerting |
| Networking | Ubiquiti UniFi | VLANs, firewall, switching |

---

## Repo Structure

```
homelab/
├── proxmox-install/         # Unattended Proxmox ISO install
│   ├── answer-file.toml     # Proxmox 8 answer file for automated install
│   └── README.md            # How to use the answer file
│
├── ansible/                 # Post-install config & app deployment
│   ├── site.yml             # Master playbook
│   ├── inventory/
│   │   ├── hosts.yml        # Host definitions
│   │   └── group_vars.yml   # Shared variables
│   └── roles/
│       ├── proxmox-base/    # Proxmox host hardening & config
│       ├── docker/          # Docker + Compose install
│       └── monitoring/      # Deploy the monitoring stack
│
├── terraform/               # VM provisioning
│   ├── modules/
│   │   └── vm/              # Reusable VM module
│   └── environments/
│       └── prod/            # Production environment config
│
├── docker/
│   └── monitoring/
│       ├── docker-compose.yml  # Grafana + Prometheus + Loki
│       ├── prometheus.yml      # Scrape config
│       └── .env.example        # Environment variable template
│
└── docs/
    ├── architecture/        # Architecture diagrams & decisions
    └── runbooks/            # Step-by-step operational guides
```

---

## Quick Start

### Prerequisites
- Dell OptiPlex (or similar x86_64 machine)
- Proxmox VE 8 ISO downloaded
- Ansible and Terraform installed on your workstation
- SSH key pair generated

### 1. Install Proxmox (Unattended)
See [`proxmox-install/README.md`](proxmox-install/README.md) for full instructions.

```bash
# Copy answer file to a USB alongside the Proxmox ISO
# Boot from USB — install completes automatically
```

### 2. Configure Proxmox Host
```bash
cd ansible
cp inventory/hosts.yml.example inventory/hosts.yml
# Edit hosts.yml with your Proxmox IP

ansible-playbook -i inventory/hosts.yml site.yml --tags proxmox-base
```

### 3. Provision the Monitoring VM
```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

### 4. Deploy the Monitoring Stack
```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags monitoring
```

Grafana will be available at `http://<vm-ip>:3000`

---

## Monitoring Dashboards

| Dashboard | Description |
|---|---|
| Node Exporter | Host CPU, memory, disk, network |
| Proxmox | VM/LXC resource usage |
| UniFi | Switch ports, AP clients, WAN throughput |
| Loki Logs | Aggregated logs from all services |

---

## Networking (Ubiquiti)

VLANs are segmented as follows:

| VLAN | Name | Subnet | Purpose |
|---|---|---|---|
| 1 | Management | 10.0.1.0/24 | Proxmox, UniFi controller |
| 10 | Servers | 10.0.10.0/24 | VMs and services |
| 20 | IoT | 10.0.20.0/24 | IoT devices (isolated) |

---

## Roadmap

- [x] Proxmox answer file (unattended install)
- [x] Ansible: Proxmox base configuration
- [x] Ansible: Docker install role
- [x] Terraform: VM module
- [x] Monitoring stack (Grafana + Prometheus + Loki)
- [ ] Ubiquiti UniFi exporter for Prometheus
- [ ] Automated backups with Proxmox Backup Server
- [ ] Gitea self-hosted Git mirror
- [ ] CI/CD pipeline with Woodpecker CI

---

## License

MIT
