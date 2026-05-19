terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.target_node
  clone       = var.clone_template

  cores  = var.cores
  memory = var.memory

  disk {
    slot    = 0
    size    = var.disk_size
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=${var.ip_address},gw=${var.gateway}"
  sshkeys   = var.ssh_public_key

  lifecycle {
    ignore_changes = [network]
  }
}
