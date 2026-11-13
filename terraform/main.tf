# =========================================================================
# PROXMOX VIRTUAL MACHINE & STORAGE PROVISIONING
# =========================================================================

# 1. Stage QCOW2 disk image onto Proxmox datastore
resource "proxmox_virtual_environment_file" "appliance_disk" {
  content_type = "iso"
  datastore_id = var.datastore_iso
  node_name    = var.proxmox_node_name
  overwrite    = true

  source_file {
    path      = var.local_disk_path
    file_name = "${var.appliance_name}-${var.image_tag}.img"
  }
}

# 2. Instantiate and boot all virtual machines defined in terraform.tfvars
resource "proxmox_virtual_environment_vm" "appliances" {
  for_each = var.virtual_machines

  name        = "srv-${each.key}"
  description = "${each.value.description} (${var.appliance_name}:${var.image_tag})"
  node_name   = var.proxmox_node_name
  vm_id       = each.value.vm_id
  started     = true

  # Enable QEMU Guest Agent for IP reporting and graceful shutdowns
  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  network_device {
    bridge = var.network_bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = each.value.gateway_ip
      }
    }
  }

  # Dynamic disk allocation: scsi0 gets the BootC OS image, others are blank data volumes
  dynamic "disk" {
    for_each = each.value.storage_disks
    content {
      datastore_id = var.datastore_vm
      interface    = disk.value.interface
      size         = disk.value.size_gb
      file_id      = disk.value.interface == "scsi0" ? proxmox_virtual_environment_file.appliance_disk.id : null
    }
  }

  # UEFI firmware required for modern RHEL BootC deployments
  bios = "ovmf"
  efi_disk {
    datastore_id = var.datastore_vm
    type         = "4m"
  }
}
