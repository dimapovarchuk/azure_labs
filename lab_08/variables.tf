# General variables with defaults
variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "az104-rg8"
}

variable "location" {
  description = "Azure region"
  default     = "eastus"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  default     = "myVNet"
}

variable "vm_name1" {
  description = "Name of the first VM"
  default     = "az104-vm1"
}

variable "vm_name2" {
  description = "Name of the second VM"
  default     = "az104-vm2"
}

variable "vmss_name" {
  description = "Name of the VMSS"
  default     = "vmss1"
}

variable "vm_size" {
  description = "Size of the VMs"
  default     = "Standard_D2s_v3"
}

# Sensitive variables without defaults
variable "vm_username" {
  description = "Admin username"
  sensitive   = true
}

variable "vm_password" {
  description = "Admin password"
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  sensitive   = true
}

variable "client_id" {
  description = "Azure Client ID"
  sensitive   = true
}

variable "client_secret" {
  description = "Azure Client Secret"
  sensitive   = true
}