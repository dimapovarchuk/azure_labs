output "resource_group_name" {
  value = azurerm_resource_group.rg.name
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