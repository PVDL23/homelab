terraform {
  required_version = ">= 1.15"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.107.0"
    }
    unifi = {
      source = "ubiquiti-community/unifi"
    }
    talos = {
      source = "siderolabs/talos"
    }
  }

  backend "s3" {
    bucket = "homelab-terraform-state"
    key    = "proxmox/terraform.tfstate"
    region = "fr-par"

    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }

    encrypt = true

    # Required for non-AWS S3 providers (Scaleway doesn't implement these AWS APIs)
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    use_path_style              = true
    use_lockfile                = true

    # Credentials from env: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    # (set these to your Scaleway access key / secret key in ~/.bashrc)
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true
  # PROXMOX_VE_API_TOKEN read from env: "user@realm!tokenid=secret"
}

provider "unifi" {
  api_url        = var.unifi_api_url
  allow_insecure = true
}

provider "talos" {}

