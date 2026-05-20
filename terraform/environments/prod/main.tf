terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  username  = var.proxmox_user
  password  = var.proxmox_password
  insecure  = true   # Set false if you add a real TLS cert to Proxmox
}

module "monitoring_vm" {
  source = "../../modules/vm"

  vm_name           = "monitoring"
  vm_id             = 100
  target_node       = var.target_node
  clone_template_id = var.clone_template_id
  cores             = 2
  memory            = 4096
  disk_size         = 32
  ip_address        = var.monitoring_ip
  gateway           = var.gateway
  ssh_public_key    = var.ssh_public_key
}

module "pbs_vm" {
  source = "../../modules/vm"

  vm_name           = "pbs"
  vm_id             = 101
  target_node       = var.target_node
  clone_template_id = var.debian_template_id
  cores             = 2
  memory            = 4096
  disk_size         = 16
  data_disk_size    = 60
  ip_address        = var.pbs_ip
  gateway           = var.gateway
  ssh_public_key    = var.ssh_public_key
}

variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g. https://192.168.1.37:8006/api2/json)"
  type        = string
}

variable "target_node" {
  description = "Proxmox node name (shown in the Proxmox UI, typically 'pve')"
  type        = string
  default     = "pve"
}

variable "clone_template_id" {
  description = "VM ID of the Proxmox cloud-init template to clone (see runbook Step 4)"
  type        = number
  default     = 9000
}

variable "proxmox_user" {
  description = "Proxmox API user (e.g. root@pam)"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "monitoring_ip" {
  description = "Static IP for monitoring VM"
  type        = string
  default     = "10.0.10.10/24"
}

variable "pbs_ip" {
  description = "Static IP for Proxmox Backup Server VM"
  type        = string
  default     = "192.168.1.51/24"
}

variable "debian_template_id" {
  description = "VM ID of the Debian 12 cloud-init template (for PBS)"
  type        = number
  default     = 9001
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "10.0.10.1"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
}
