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
ssh root@10.0.1.10   # Your Proxmox IP
```

## Step 3: Run Ansible Base Config

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags proxmox-base
```

## Step 4: Create Ubuntu Cloud-Init Template in Proxmox

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

## Step 5: Provision VMs with Terraform

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars

export TF_VAR_proxmox_password="your_proxmox_password"

terraform init
terraform plan
terraform apply
```

## Step 6: Deploy Monitoring Stack

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags monitoring
```

Open Grafana at `http://10.0.10.10:3000`
Default login: `admin / changeme` (change immediately!)
