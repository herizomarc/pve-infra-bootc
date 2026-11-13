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

# 2. Generate dynamic Cloud-Init snippet from template
resource "proxmox_virtual_environment_file" "cloud_init_config" {
  for_each     = var.virtual_machines
  content_type = "snippets"
  datastore_id = var.datastore_iso
  node_name    = var.proxmox_node_name
  overwrite    = true

  source_raw {
    file_name = "${each.key}-user-data.yml"
    data = templatefile("/templates/zabbix.yml.tmpl", {
      ssh_key = trimspace(var.secops_ssh_public_key)
    })
  }
}

# 3. Instantiate and boot all virtual machines defined in terraform.tfvars
resource "proxmox_virtual_environment_vm" "appliances" {
  for_each = var.virtual_machines

  name        = "srv-${each.key}"
  description = "${each.value.description} (${var.appliance_name}:${var.image_tag})"
  node_name   = var.proxmox_node_name
  vm_id       = each.value.vm_id
  started     = true

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
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config[each.key].id

    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = each.value.gateway_ip
      }
    }
  }

  dynamic "disk" {
    for_each = each.value.storage_disks
    content {
      datastore_id = var.datastore_vm
      interface    = disk.value.interface
      size         = disk.value.size_gb
      file_format  = "raw"
      file_id      = disk.value.interface == "scsi0" ? proxmox_virtual_environment_file.appliance_disk.id : null
    }
  }

  bios = "ovmf"
  efi_disk {
    datastore_id = var.datastore_vm
    type         = "4m"
  }
}
