# =========================================================================
# INPUT VARIABLES DECLARATION (SECRETS, TOPOLOGY & DATA-DRIVEN MATRIX)
# =========================================================================

# --- SECRETS (INJECTED FROM OPENBAO SSOT) ---
variable "proxmox_api_token_id" {
  type        = string
  sensitive   = true
  description = "Proxmox API token identifier"
}

variable "proxmox_api_token_secret" {
  type        = string
  sensitive   = true
  description = "Proxmox API token secret"
}

# --- ENVIRONMENT TOPOLOGY (INJECTED FROM GITLAB CI VARIABLES) ---
variable "proxmox_api_endpoint" {
  type        = string
  description = "Proxmox VE API URL"
}

variable "proxmox_node_name" {
  type        = string
  description = "Target Proxmox cluster node name"
}

variable "proxmox_ssh_user" {
  type        = string
  default     = "root"
  description = "SSH username on the Proxmox hypervisor"
}

# --- PIPELINE ARTIFACT & STORAGE PARAMETERS ---
variable "appliance_name" {
  type        = string
  description = "Immutable OS appliance identifier"
}

variable "image_tag" {
  type        = string
  description = "Git short SHA tag of the built OCI image"
}

variable "local_disk_path" {
  type        = string
  description = "Local path of the QCOW2 disk mounted inside the OpenTofu container"
}

variable "datastore_iso" {
  type        = string
  default     = "local"
  description = "Proxmox datastore for staging uploaded disk images"
}

variable "datastore_vm" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox high-performance datastore for VM block volumes"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Proxmox virtual network bridge"
}

# --- DATA-DRIVEN VM MATRIX (LOADED FROM TERRAFORM.TFVARS) ---
variable "virtual_machines" {
  description = "Declarative map of virtual machines, network settings, and storage layouts"
  type = map(object({
    vm_id       = number
    cpu_cores   = number
    memory_mb   = number
    ip_address  = string
    gateway_ip  = string
    description = string
    storage_disks = list(object({
      interface = string
      size_gb   = number
    }))
  }))
}
