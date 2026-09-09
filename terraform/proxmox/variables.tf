variable "proxmox_endpoint" {
  description = "Proxmox API URL (e.g. https://proxmox:8006/api2/json)"
  type        = string
  # Credentials read from env: PROXMOX_VE_API_TOKEN="user@realm!tokenid=secret"
  # e.g. export PROXMOX_VE_API_TOKEN="terraform@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "proxmox_user" {
  description = "Promox username for SSH"
  type        = string
  sensitive   = true
}

variable "proxmox_password" {
  description = "Promox password for SSH"
  type        = string
  sensitive   = true
}

variable "storage_pool" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-vm-lvm"
}

variable "datastore" {
  description = "Name of datastore for VM disks (e.g. 'nas')"
  type        = string
  default     = "nas"
}

variable "ssh_authorized_key" {
  description = "SSH public key to inject into all VMs"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for VM provisioning"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "unifi_api_url" {
  description = "Unifi API URL (e.g. https://unifi:8443)"
  type        = string
  # Credentials read from env: UNIFI_USERNAME and UNIFI_PASSWORD
}
