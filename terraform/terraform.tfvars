# =========================================================================
# MATRICIAL INSTANTIATION MAP: DATA-DRIVEN INFRASTRUCTURE DECLARATION
# =========================================================================

virtual_machines = {
  "zabbix-prod" = {
    vm_id       = 105
    cpu_cores   = 2
    memory_mb   = 4096
    ip_address  = "10.10.99.30/24"
    gateway_ip  = "10.10.99.1"
    description = "Production Sovereign Zabbix Monitoring Server"
    
    # scsi0 receives the immutable BootC OS; additional interfaces create dedicated data disks
    storage_disks = [
      { interface = "scsi0", size_gb = 20 },
      { interface = "scsi1", size_gb = 15 }
    ]
  }
}
