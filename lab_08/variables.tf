# Azure Authentication Variables
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Azure Client ID (Service Principal)"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Azure Client Secret (Service Principal)"
  type        = string
  sensitive   = true
}

# Resource Group Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "az104-rg8"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

# Network Variables
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "myVNet"
}

variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for Subnet"
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

# Virtual Machine Variables
variable "vm_name1" {
  description = "Name of the first VM"
  type        = string
  default     = "az104-vm1"
}

variable "vm_name2" {
  description = "Name of the second VM"
  type        = string
  default     = "az104-vm2"
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vm_username" {
  description = "Admin username for VMs"
  type        = string
  sensitive   = true
}

variable "vm_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

# VMSS Variables
variable "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  type        = string
  default     = "vmss1"
}

variable "vmss_instances" {
  description = "Number of instances in VMSS"
  type        = number
  default     = 1
}

# Storage Account Variables
variable "storage_account_tier" {
  description = "Storage Account Tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Storage Account Replication Type"
  type        = string
  default     = "LRS"
}

variable "container_name" {
  description = "Name of the storage container"
  type        = string
  default     = "data"
}