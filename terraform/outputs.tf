# =========================================================================
# DEPLOYMENT OUTPUTS
# =========================================================================

output "deployed_appliances" {
  description = "Summary of provisioned virtual machines and assigned IP addresses"
  value = {
    for k, vm in proxmox_virtual_environment_vm.appliances : k => {
      vm_id   = vm.vm_id
      name    = vm.name
      ip_list = vm.ipv4_addresses
    }
  }
}
