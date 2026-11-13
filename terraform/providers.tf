# =========================================================================
# OPENTOFU PROVIDERS & REMOTE STATE BACKEND CONFIGURATION
# =========================================================================

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.0"
    }
  }

  # GitLab Managed Terraform State (HTTP Backend)
  backend "http" {}
}

provider "proxmox" {
  endpoint  = var.proxmox_api_endpoint
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true

  # Authenticate via forwarded SSH agent socket (Zero private key on disk)
  ssh {
    agent    = true
    username = var.proxmox_ssh_user
  }
}
