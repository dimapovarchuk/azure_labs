# Resource Group Outputs
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

# Storage Account Outputs
output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "storage_container_name" {
  description = "The name of the storage container"
  value       = azurerm_storage_container.container.name
}

# Virtual Machine Outputs
output "vm1_name" {
  description = "The name of VM1"
  value       = azurerm_windows_virtual_machine.vm1.name
}

output "vm2_name" {
  description = "The name of VM2"
  value       = azurerm_windows_virtual_machine.vm2.name
}

# VMSS Outputs
output "vmss_name" {
  description = "The name of the VMSS"
  value       = azurerm_windows_virtual_machine_scale_set.vmss.name
}

# Load Balancer Outputs
output "load_balancer_public_ip" {
  description = "The public IP address of the load balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}