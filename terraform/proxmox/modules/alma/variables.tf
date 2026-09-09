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

variable "cloud_image_id" {
  description = "Proxmox file ID of the cloud image to import (e.g. local:iso/AlmaLinux-Kitten-10-GenCloud-x86_64-latest.img)"
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

variable "ssh_authorized_key" {
  description = "SSH public key to add to the almalinux user"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for post-create IP provisioning"
  type        = string
  default     = "~/.ssh/id_ed25519"
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
