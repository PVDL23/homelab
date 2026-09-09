locals {
  gateway        = "10.23.1.1"
  network_prefix = 24

  alma_nodes = {
    "vault-01" = {
      vm_id            = 101
      ip               = "10.23.1.30"
      description      = "HashiCorp Vault - PKI CA and secrets management"
      cores            = 2
      memory           = 4096
      disk_size        = 50
      tags             = ["terraform", "vault"]
      startup_order    = 1
      startup_up_delay = 30
      firewall_rules = [
        {
          comment = "SSH"
          dport   = "22"
          proto   = "tcp"
        },
        {
          comment = "Vault API"
          dport   = "8200"
          proto   = "tcp"
        },
        {
          comment = "Vault cluster (raft replication)"
          dport   = "8201"
          proto   = "tcp"
        },
      ]
    }
    "docker-01" = {
      vm_id            = 102
      ip               = "10.23.1.31"
      description      = "Docker host"
      cores            = 6
      memory           = 16384
      disk_size        = 150
      tags             = ["terraform", "docker"]
      startup_order    = 2
      startup_up_delay = 30
      firewall_rules = [
        {
          comment = "SSH"
          dport   = "22"
          proto   = "tcp"
        },
      ]
    }
  }
}

resource "proxmox_download_file" "almalinux_gencloud" {
  content_type = "import"
  datastore_id = var.datastore
  node_name    = var.proxmox_node
  url          = "https://repo.almalinux.org/almalinux/10/cloud/x86_64/images/AlmaLinux-10-GenericCloud-latest.x86_64.qcow2"
  file_name    = "AlmaLinux-10-GenericCloud-latest.qcow2"
  overwrite    = false
}

module "alma_vms" {
  for_each   = local.alma_nodes
  depends_on = [proxmox_download_file.almalinux_gencloud]

  source = "./modules/alma"

  name         = each.key
  vm_id        = each.value.vm_id
  description  = each.value.description
  proxmox_node = var.proxmox_node

  cloud_image_id = proxmox_download_file.almalinux_gencloud.id

  cores        = each.value.cores
  memory       = each.value.memory
  disk_size    = each.value.disk_size
  storage_pool = var.storage_pool

  ip_address    = each.value.ip
  gateway       = local.gateway
  prefix_length = local.network_prefix
  nameserver    = local.gateway

  ssh_authorized_key   = var.ssh_authorized_key
  ssh_private_key_path = var.ssh_private_key_path
  tags                 = each.value.tags

  startup_order    = each.value.startup_order
  startup_up_delay = each.value.startup_up_delay
}
