locals {
  kubernetes_version = "v1.37.1"
  talos_version      = "v1.14.2"
  gateway            = "10.23.2.1"
  network_prefix     = 24

  memory_control = 8192
  memory_worker  = 20480

  cluster_endpoint = "https://${local.talos_nodes["control-01"].ip}:6443"

  talos_nodes = {
    "control-01" = {
      vm_id          = 200
      ip             = "10.23.2.10"
      description    = "Talos Controller Node 1"
      tags           = ["terraform", "talos", "controller"]
      bios           = "ovmf"
      machine        = "q35"
      cpu_type       = "host"
      cpu_cores      = 4
      memory         = local.memory_control
      disk_size      = 50
      scsi_hardware  = "virtio-scsi-pci"
      disk_cache     = "writethrough"
      network_model  = "virtio"
      efi_disk       = "4m"
      ballooning     = 0
      vlan_id        = 4
      gateway        = "10.23.2.1"
      install_disk   = "/dev/vda"
      data_disk_size = 0
    }
    "worker-01" = {
      vm_id          = 201
      ip             = "10.23.2.11"
      description    = "Talos Worker Node 1"
      tags           = ["terraform", "talos", "worker"]
      bios           = "ovmf"
      machine        = "q35"
      cpu_type       = "host"
      cpu_cores      = 4
      memory         = local.memory_worker
      disk_size      = 50
      scsi_hardware  = "virtio-scsi-pci"
      disk_cache     = "writethrough"
      network_model  = "virtio"
      efi_disk       = "4m"
      ballooning     = 0
      vlan_id        = 4
      gateway        = "10.23.2.1"
      install_disk   = "/dev/vda"
      data_disk_size = 50
    }
    "worker-02" = {
      vm_id          = 202
      ip             = "10.23.2.12"
      description    = "Talos Worker Node 2"
      tags           = ["terraform", "talos", "worker"]
      bios           = "ovmf"
      machine        = "q35"
      cpu_type       = "host"
      cpu_cores      = 4
      memory         = local.memory_worker
      disk_size      = 50
      scsi_hardware  = "virtio-scsi-pci"
      disk_cache     = "writethrough"
      network_model  = "virtio"
      efi_disk       = "4m"
      ballooning     = 0
      vlan_id        = 4
      gateway        = "10.23.2.1"
      install_disk   = "/dev/vda"
      data_disk_size = 50
    }
    "worker-03" = {
      vm_id          = 203
      ip             = "10.23.2.13"
      description    = "Talos Worker Node 3"
      tags           = ["terraform", "talos", "worker"]
      bios           = "ovmf"
      machine        = "q35"
      cpu_type       = "host"
      cpu_cores      = 4
      memory         = local.memory_worker
      disk_size      = 50
      scsi_hardware  = "virtio-scsi-pci"
      disk_cache     = "writethrough"
      network_model  = "virtio"
      efi_disk       = "4m"
      ballooning     = 0
      vlan_id        = 4
      gateway        = "10.23.2.1"
      install_disk   = "/dev/vda"
      data_disk_size = 50
    }
  }

  controlplane_nodes = { for k, v in local.talos_nodes : k => v if contains(v.tags, "controller") }
  worker_nodes       = { for k, v in local.talos_nodes : k => v if contains(v.tags, "worker") }
}

data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = local.talos_version
  filters = {
    names = [
      "qemu-guest-agent"
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "this" {
  talos_version = local.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
  architecture  = "amd64"
}

resource "proxmox_download_file" "talos" {
  content_type        = "iso"
  datastore_id        = "nas"
  file_name           = "Talos-${local.talos_version}-nocloud.iso"
  node_name           = "pve"
  overwrite           = true
  overwrite_unmanaged = false
  upload_timeout      = 600

  url = data.talos_image_factory_urls.this.urls.iso

  verify = true
}

module "talos_cluster" {
  for_each   = local.talos_nodes
  depends_on = [proxmox_download_file.talos]

  source = "./modules/talos"

  name         = each.key
  vm_id        = each.value.vm_id
  description  = each.value.description
  proxmox_node = var.proxmox_node

  iso_id    = proxmox_download_file.talos.id
  datastore = var.datastore

  bios          = each.value.bios
  machine       = each.value.machine
  cpu_type      = each.value.cpu_type
  cores         = each.value.cpu_cores
  memory        = each.value.memory
  disk_size     = each.value.disk_size
  storage_pool  = var.storage_pool
  scsi_hardware = each.value.scsi_hardware
  disk_cache    = each.value.disk_cache
  network_model = each.value.network_model
  efi_disk      = each.value.efi_disk
  ballooning    = each.value.ballooning

  ip_address    = each.value.ip
  gateway       = each.value.gateway
  prefix_length = local.network_prefix
  nameserver    = local.gateway
  vlan_id       = each.value.vlan_id

  data_disk_size = each.value.data_disk_size

  tags = each.value.tags
}

resource "talos_machine_secrets" "this" {
  talos_version = local.talos_version
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = local.kubernetes_version
  talos_version      = local.talos_version
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = local.kubernetes_version
  talos_version      = local.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for k, v in local.controlplane_nodes : v.ip]
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [module.talos_cluster]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = local.controlplane_nodes
  node                        = each.value.ip
  config_patches = [
    templatefile("${path.module}/templates/install-disk-and-hostname.yaml.tmpl", {
      install_disk    = each.value.install_disk
      installer_image = "factory.talos.dev/nocloud-installer/${talos_image_factory_schematic.this.id}:${local.talos_version}"
      hostname        = each.key
      ip_address      = each.value.ip
      gateway         = each.value.gateway
    }),
    file("${path.module}/files/cp-scheduling.yaml"),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [module.talos_cluster]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = local.worker_nodes
  node                        = each.value.ip
  config_patches = [
    templatefile("${path.module}/templates/install-disk-and-hostname.yaml.tmpl", {
      install_disk    = each.value.install_disk
      installer_image = "factory.talos.dev/nocloud-installer/${talos_image_factory_schematic.this.id}:${local.talos_version}"
      hostname        = each.key
      ip_address      = each.value.ip
      gateway         = each.value.gateway
    }),
    file("${path.module}/files/local-path-user-volume.yaml"),
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in local.controlplane_nodes : v.ip][0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in local.controlplane_nodes : v.ip][0]
}
