terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true   # Set false if you add a real TLS cert to Proxmox
}

module "monitoring_vm" {
  source = "../../modules/vm"

  vm_name        = "monitoring"
  vm_id          = 100
  cores          = 2
  memory         = 4096
  disk_size      = "32G"
  ip_address     = var.monitoring_ip
  gateway        = var.gateway
  ssh_public_key = var.ssh_public_key
}

variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g. https://10.0.1.10:8006/api2/json)"
  type        = string
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

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "10.0.10.1"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
}
