# Runbook: Initial Homelab Setup

## Prerequisites

Install these on your workstation before starting:

```bash
# macOS (Homebrew)
brew install ansible terraform

# Ubuntu/Debian
sudo apt install ansible
# Terraform: https://developer.hashicorp.com/terraform/install
```

```powershell
# Windows
wsl --install

# inside WSL
sudo apt update
sudo apt install ansible
```

Generate an SSH key pair if you don't have one:

```bash
ssh-keygen -t ed25519 -C "homelab"
cat ~/.ssh/id_ed25519.pub   # Copy this into answer-file.toml
```

## Step 1: Install Proxmox

See `proxmox-install/README.md`.

## Step 2: Verify SSH Access

```bash
ssh root@<your-proxmox-ip>
```

## Step 3: Create Terraform Role in Proxmox

The Terraform provider requires explicit API permissions even for root. Run on the Proxmox host:

```bash
pveum role add Terraform -privs "VM.Allocate,VM.Audit,VM.Clone,VM.Config.CDROM,VM.Config.Cloudinit,VM.Config.CPU,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Migrate,VM.PowerMgmt,Datastore.AllocateSpace,Datastore.Audit,SDN.Use,Sys.Audit,Sys.Modify,Pool.Allocate"

pveum acl modify / -role Terraform -user root@pam
```

> **Note:** `VM.Monitor` is not a valid privilege in Proxmox 8+/9 and should not be included. The `bpg/proxmox` Terraform provider is used here for Proxmox 8+/9 compatibility.

## Step 4: Run Ansible Base Config

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags proxmox-base
```

## Step 5: Create Ubuntu Cloud-Init Template in Proxmox

Terraform clones this template to create VMs. Run on the Proxmox host:

```bash
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
qm create 9000 --name ubuntu-22.04-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```

## Step 6: Provision VMs with Terraform

Copy the example tfvars and fill in your values:

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox IP, password, VM IP, gateway, and SSH public key
```

> **Note:** Use `cat ~/.ssh/id_ed25519.pub` to get your public key. The entire key must be on a single line in terraform.tfvars.

> **Note:** The Proxmox API user is `root@pam` — this is correct even though your SSH prompt shows `root@pve`. They are different things.

```bash
terraform init
terraform plan
terraform apply
```

After apply, add the new VM's IP to `ansible/inventory/hosts.yml` under `monitoring_vms`.

## Step 7: Accept SSH Host Key for New VMs

Before running Ansible against a newly provisioned VM, SSH in once manually to accept the host key:

```bash
ssh ubuntu@<vm-ip>   # type 'yes' when prompted, then exit
```

> **Note:** Ubuntu cloud images use `ubuntu` as the default user, not `root`. The Ansible inventory sets `ansible_user: ubuntu` for `monitoring_vms` to account for this.

## Step 8: Deploy Monitoring Stack

Install Docker first, then deploy the stack:

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags docker
ansible-playbook -i inventory/hosts.yml site.yml --tags monitoring
```

Open Grafana at `http://<vm-ip>:3000`
Default login: `admin / changeme` (change immediately!)

Prometheus and Loki are automatically configured as datasources via provisioning. Verify at **Connections → Data Sources**.
