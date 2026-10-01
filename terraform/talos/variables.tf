variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
  default     = "talos-cluster"
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster"
  type        = string
  default     = "https://talos-cluster.homelab.lan:6443"
}

variable "proxmox_endpoint" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "proxmox_user" {
  description = "Proxmox username for SSH"
  type        = string
  sensitive   = true
}

variable "proxmox_password" {
  description = "Proxmox password for SSH"
  type        = string
  sensitive   = true
}

variable "storage_pool" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-vm-lvm"
}

variable "datastore" {
  description = "Name of datastore for VM disks"
  type        = string
  default     = "nas"
}

variable "ssh_authorized_key" {
  description = "SSH public key"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_ed25519"
}
