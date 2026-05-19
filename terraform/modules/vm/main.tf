terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  vm_id     = var.vm_id
  node_name = var.target_node

  clone {
    vm_id = var.clone_template_id
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.disk_size
  }

  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      keys = [var.ssh_public_key]
    }
  }
}
