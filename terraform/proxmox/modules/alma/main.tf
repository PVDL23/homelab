resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  description = var.description
  tags        = var.tags
  on_boot     = var.onboot
  pool_id     = var.pool_id

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "virtio0"
    size         = var.disk_size
    discard      = "on"
    iothread     = true
    file_format  = "raw"
    import_from  = var.cloud_image_id
  }

  network_device {
    bridge  = "vmbr0"
    model   = "virtio"
    vlan_id = var.vlan_id
  }

  initialization {
    datastore_id = var.storage_pool
    upgrade      = false

    dns {
      servers = [var.nameserver]
      domain  = var.searchdomain
    }

    ip_config {
      ipv4 {
        address = "${var.ip_address}/${var.prefix_length}"
        gateway = var.gateway
      }
    }

    user_account {
      username = "almalinux"
      keys     = [var.ssh_authorized_key]
    }
  }

  dynamic "startup" {
    for_each = var.startup_order > 0 ? [1] : []
    content {
      order      = tostring(var.startup_order)
      up_delay   = var.startup_up_delay
      down_delay = var.startup_down_delay
    }
  }

  lifecycle {
    ignore_changes = [
      # Prevent perpetual diffs from Proxmox updating MAC addresses
      network_device,
    ]
  }
}
