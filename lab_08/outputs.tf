output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}

output "storage_container_name" {
  value = azurerm_storage_container.container.name
}

output "vm1_name" {
  value = azurerm_windows_virtual_machine.vm1.name
}

output "vm2_name" {
  value = azurerm_windows_virtual_machine.vm2.name
}

output "vmss_name" {
  value = azurerm_windows_virtual_machine_scale_set.vmss.name
}