resource "proxmox_virtual_environment_vm" "talos" {
  name      = var.name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  description = var.description
  tags        = var.tags
  on_boot     = var.onboot
  pool_id     = var.pool_id

  bios    = var.bios
  machine = var.machine


  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
    floating  = var.ballooning > 0 ? var.memory : 0
  }

  cdrom {
    file_id = var.iso_id
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "virtio0"
    size         = var.disk_size
    discard      = "on"
    iothread     = true
    file_format  = "raw"
  }

  dynamic "disk" {
    for_each = var.data_disk_size > 0 ? [1] : []
    content {
      datastore_id = var.storage_pool
      interface    = "virtio1"
      size         = var.data_disk_size
      discard      = "on"
      iothread     = true
      file_format  = "raw"
    }
  }

  boot_order = ["ide2", "virtio0"]

  network_device {
    bridge  = "vmbr0"
    model   = var.network_model
    vlan_id = var.vlan_id
  }

  efi_disk {
    datastore_id = var.storage_pool
    type         = var.efi_disk
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${var.ip_address}/24"
        gateway = var.gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      network_device
    ]
  }
}
