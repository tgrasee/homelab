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
│   │              Proxmox VE 9.x                 │   │
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
| Hypervisor | Proxmox VE 9 | Bare metal virtualization |
| Bare metal provisioning | Proxmox Answer File | Unattended OS install |
| Configuration management | Ansible | Post-install config & app deployment |
| Infrastructure as Code | Terraform | VM/LXC lifecycle management |
| Backups | Proxmox Backup Server | Automated nightly VM snapshots |
| Containerization | Docker + Compose | App packaging |
| Metrics | Prometheus | Time-series metrics collection |
| Logging | Loki + Promtail | Log aggregation |
| Visualization | Grafana | Dashboards & alerting |
| UniFi metrics | UnPoller | Exports UCG Ultra metrics to Prometheus |
| Source control | Gitea | Self-hosted Git service |
| CI/CD | Woodpecker CI | Pipeline automation integrated with Gitea |
| Networking | Ubiquiti UniFi (UCG Ultra) | VLANs, firewall, switching |

---

## Repo Structure

```
homelab/
├── proxmox-install/         # Unattended Proxmox ISO install
│   ├── answer-file.toml     # Proxmox 9 answer file for automated install
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
│       ├── monitoring/      # Deploy the monitoring stack
│       ├── proxmox-backup/  # Install & configure Proxmox Backup Server
│       └── gitea/           # Deploy Gitea + Woodpecker CI
│
├── terraform/               # VM provisioning
│   ├── modules/
│   │   └── vm/              # Reusable VM module
│   └── environments/
│       └── prod/            # Production environment config
│
├── docker/
│   ├── monitoring/
│   │   ├── docker-compose.yml          # Grafana + Prometheus + Loki + UnPoller
│   │   ├── prometheus.yml              # Scrape config
│   │   ├── .env.example                # Environment variable template
│   │   └── provisioning/
│   │       └── datasources/
│   │           └── datasources.yml    # Auto-provisions Prometheus & Loki in Grafana
│   └── gitea/
│       ├── docker-compose.yml          # Gitea + Woodpecker CI server + agent
│       └── .env.example                # Woodpecker OAuth + agent secret template
│
└── docs/
    ├── architecture/        # Architecture diagrams & decisions
    └── runbooks/            # Step-by-step operational guides
```

---

## Quick Start

### Prerequisites
- Dell OptiPlex (or similar x86_64 machine)
- Proxmox VE 9 ISO downloaded
- Ansible and Terraform installed on your workstation
- SSH key pair generated

See [`docs/runbook/initial-setup.md`](docs/runbook/initial-setup.md) for the full step-by-step guide. Summary below:

### 1. Install Proxmox (Unattended)
See [`proxmox-install/README.md`](proxmox-install/README.md) for full instructions.

### 2. Create Terraform Role in Proxmox
The `bpg/proxmox` provider requires explicit API permissions. Run on the Proxmox host:
```bash
pveum role add Terraform -privs "VM.Allocate,VM.Audit,VM.Clone,VM.Config.CDROM,VM.Config.Cloudinit,VM.Config.CPU,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Migrate,VM.PowerMgmt,Datastore.AllocateSpace,Datastore.Audit,SDN.Use,Sys.Audit,Sys.Modify,Pool.Allocate"
pveum acl modify / -role Terraform -user root@pam
```

### 3. Configure Proxmox Host
```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags proxmox-base
```

### 4. Create Cloud-Init Templates & Provision VMs

Two templates are required:
- **Ubuntu 22.04** (VM ID 9000) — for the monitoring VM
- **Debian 12** (VM ID 9001) — for the PBS VM (PBS packages require Debian Bookworm)

See runbook Step 5 for the full `qm` commands for each template.

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — use 'cat ~/.ssh/id_ed25519.pub' for the SSH key value

terraform init && terraform plan && terraform apply
```

> **Note:** After provisioning each VM, SSH in once to accept the host key before running Ansible. Ubuntu VMs use `ubuntu` as the default user; Debian VMs use `debian`.

### 5. Deploy the Monitoring Stack

> **Note:** SSH into the new VM once before running Ansible to accept the host key:
> ```bash
> ssh ubuntu@<vm-ip>   # type 'yes' when prompted, then exit
> ```
> Ubuntu cloud images use `ubuntu` as the default user, not `root`.

```bash
cd ansible
# Add the new VM's IP to ansible/inventory/hosts.yml under monitoring_vms first
ansible-playbook -i inventory/hosts.yml site.yml --tags docker
ansible-playbook -i inventory/hosts.yml site.yml --tags monitoring
```

Grafana will be available at `http://<vm-ip>:3000` — Prometheus and Loki are auto-configured as datasources.

### 6. Configure UniFi Metrics (UnPoller)

Create a read-only local admin user in your UCG Ultra (UniFi OS → Users → Add User, Network role: View Only, all other apps: No Access).

Add credentials to `/opt/monitoring/.env` on the monitoring VM:
```
UNIFI_USER=unpoller
UNIFI_PASSWORD=your-password
```

Then restart Prometheus to pick up the scrape config:
```bash
sudo docker restart prometheus
```

Import the UnPoller dashboard in Grafana: **Dashboards → Import → ID `11315`**

### 7. Deploy Proxmox Backup Server

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags pbs
```

Then connect PBS to Proxmox:
1. Proxmox UI → **Datacenter → Storage → Add → Proxmox Backup Server**
2. Server: `192.168.1.51`, Username: `root@pam`, Datastore: `main`
3. Get the fingerprint from the PBS VM: `sudo proxmox-backup-manager cert info | grep Fingerprint`

Set up a backup schedule at **Datacenter → Backup → Add** (recommended: daily, Snapshot mode, ZSTD compression).

> **Note:** Set a root password on the PBS VM via SSH before accessing the web UI: `sudo passwd root`

### 8. Deploy Gitea & Woodpecker CI

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags docker --limit gitea_vms
ansible-playbook -i inventory/hosts.yml site.yml --tags gitea
```

Access Gitea at `http://192.168.1.52:3000` and complete the setup wizard, then:

1. Create an OAuth2 app in Gitea: **Settings → Applications → Manage OAuth2 Applications**
   - Redirect URI: `http://192.168.1.52:8000/authorize`
2. Add credentials to `/opt/gitea/.env` on the Gitea VM:
   ```
   WOODPECKER_AGENT_SECRET=<random-string>
   WOODPECKER_ADMIN=<your-gitea-username>
   WOODPECKER_GITEA_CLIENT=<oauth-client-id>
   WOODPECKER_GITEA_SECRET=<oauth-client-secret>
   ```
3. Restart the stack: `sudo docker compose down && sudo docker compose up -d`

Woodpecker CI is available at `http://192.168.1.52:8000` — log in with **Login with Gitea**.

> **Note:** Woodpecker uses versioned image tags — `v3` is used instead of `latest` which has been removed.

---

## Monitoring Dashboards

| Dashboard | Grafana ID | Description |
|---|---|---|
| Node Exporter | 1860 | Host CPU, memory, disk, network |
| Proxmox | - | VM/LXC resource usage |
| UniFi (UnPoller) | 11315 | UCG Ultra — clients, AP stats, WAN throughput |
| Loki Logs | - | Aggregated logs from all services |

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
- [x] Ubiquiti UniFi exporter for Prometheus (UnPoller → UCG Ultra)
- [x] Automated backups with Proxmox Backup Server (VM 101, nightly snapshots)
- [x] Gitea self-hosted Git mirror (VM 102, port 3000)
- [x] CI/CD pipeline with Woodpecker CI (port 8000, OAuth via Gitea)

---

## License

MIT
