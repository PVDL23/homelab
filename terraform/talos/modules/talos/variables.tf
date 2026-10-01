variable "name" {
  description = "VM name"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID (null = auto-assign)"
  type        = number
  default     = null
  nullable    = true
}

variable "description" {
  description = "VM description shown in Proxmox UI"
  type        = string
  default     = ""
}

variable "proxmox_node" {
  description = "Proxmox node to create the VM on"
  type        = string
  default     = "pve"
}

variable "iso_id" {
  description = "Proxmox file ID of the Talos ISO to boot from"
  type        = string
}

variable "datastore" {
  description = "Datastore ID where the ISO is stored"
  type        = string
}

variable "pool_id" {
  description = "Proxmox pool to assign this VM to (null = no pool)"
  type        = string
  default     = null
  nullable    = true
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM in megabytes"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Root disk size in GiB"
  type        = number
  default     = 20
}

variable "storage_pool" {
  description = "Proxmox storage pool for VM disk and cloud-init drive"
  type        = string
  default     = "local-vm-lvm"
}

variable "ip_address" {
  description = "Static IP address (e.g. '10.23.1.30')"
  type        = string
}

variable "gateway" {
  description = "Default gateway IP"
  type        = string
  default     = "10.23.1.1"
}

variable "prefix_length" {
  description = "Subnet prefix length (e.g. 24 for /24)"
  type        = number
  default     = 24
}

variable "nameserver" {
  description = "DNS nameserver IP"
  type        = string
  default     = "10.23.1.1"
}

variable "searchdomain" {
  description = "DNS search domain"
  type        = string
  default     = "homelab.lan"
}

variable "tags" {
  description = "Proxmox tags for the VM"
  type        = list(string)
  default     = ["homelab"]
}

variable "onboot" {
  description = "Start VM automatically on Proxmox host boot"
  type        = bool
  default     = true
}

variable "startup_order" {
  description = "Proxmox startup order (0 = unset, 1 = first)"
  type        = number
  default     = 0
}

variable "startup_up_delay" {
  description = "Seconds to wait after VM starts before next VM starts"
  type        = number
  default     = 0
}

variable "startup_down_delay" {
  description = "Seconds to wait before shutdown when stopping all VMs"
  type        = number
  default     = 0
}

variable "vlan_id" {
  description = "VLAN tag for the network interface (null = untagged)"
  type        = number
  default     = null
  nullable    = true
}

# Talos-specific variables
variable "efi_disk" {
  description = "EFI disk size (e.g., '4m'). Set to null to disable"
  type        = string
  default     = null
  nullable    = true
}

variable "ballooning" {
  description = "Memory ballooning in MiB. Set to 0 to disable"
  type        = number
  default     = 0
}

# Talos-specific variables
variable "bios" {
  description = "BIOS type (e.g., 'ovmf' for UEFI, 'seabios' for legacy)"
  type        = string
  default     = "seabios"
}

variable "machine" {
  description = "Machine type (e.g., 'q35' for UEFI)"
  type        = string
  default     = "pc"
}

variable "cpu_type" {
  description = "CPU type"
  type        = string
  default     = "host"
}

variable "scsi_hardware" {
  description = "SCSI controller type"
  type        = string
  default     = "virtio-scsi-pci"
}

variable "disk_cache" {
  description = "Disk cache mode"
  type        = string
  default     = "none"
}

variable "network_model" {
  description = "Network device model"
  type        = string
  default     = "virtio"
}

variable "data_disk_size" {
  description = "Extra data disk size in GiB (0 = no extra disk)"
  type        = number
  default     = 0
}
