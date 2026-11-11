# =========================================================================
# 👑 OPENTOFU / TERRAFORM PROXMOX AUTOMATED PROVISIONING MANIFEST
# =========================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_endpoint
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
}

resource "proxmox_virtual_machine" "immutable_appliance" {
  name        = "srv-${var.appliance_name}-prod"
  description = "Sovereign Immutable Appliance (${var.appliance_name}) managed by OpenTofu & BootC"
  node_name   = var.proxmox_node_name
  vmid        = var.vm_id
  started     = true

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

  # Dynamic disk attachment from Proxmox ISO/IMG storage
  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/${var.disk_image_name}"
    interface    = "scsi0"
    size         = 20
  }

  # UEFI configuration required for modern RHEL BootC images
  bios = "ovmf"
  efi_disk {
    datastore_id = "local-lvm"
    type         = "4m"
  }
}

# =========================================================================
# 📊 DYNAMIC INPUT VARIABLES (INJECTED NATIVELY FROM PIPELINE RAM)
# =========================================================================
variable "proxmox_api_endpoint" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node_name" {
  type        = string
  default     = "pve1"
  description = "Target Proxmox cluster node name"
}

variable "appliance_name" {
  type        = string
  description = "Dynamic appliance identifier"
}

variable "disk_image_name" {
  type        = string
  description = "Target disk image filename on Proxmox storage"
}

variable "vm_id" {
  type        = number
  default     = 105
  description = "Unique Virtual Machine ID on Proxmox"
}
