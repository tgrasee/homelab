variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID (must be unique)"
  type        = number
}

variable "target_node" {
  description = "Proxmox node to deploy the VM on"
  type        = string
}

variable "clone_template" {
  description = "Name of the Proxmox cloud-init template to clone"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Disk size (e.g. '32G')"
  type        = string
  default     = "20G"
}

variable "ip_address" {
  description = "Static IP in CIDR notation (e.g. '10.0.10.10/24')"
  type        = string
}

variable "gateway" {
  description = "Default gateway IP"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content for cloud-init"
  type        = string
  sensitive   = true
}
