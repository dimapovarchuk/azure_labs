# Provider configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "AZ500LAB131415"
  location = "East US"
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "sentinel-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                = "PerGB2018"
  retention_in_days   = 30
}

# Microsoft Sentinel
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.law.id
}

# Azure Activity Data Connector
resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  name               = "activity-logs-sentinel"
  target_resource_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  log {
    category = "Administrative"
    enabled  = true
  }
  log {
    category = "Security"
    enabled  = true
  }
  log {
    category = "ServiceHealth"
    enabled  = true
  }
  log {
    category = "Alert"
    enabled  = true
  }
  log {
    category = "Recommendation"
    enabled  = true
  }
  log {
    category = "Policy"
    enabled  = true
  }
  log {
    category = "Autoscale"
    enabled  = true
  }
  log {
    category = "ResourceHealth"
    enabled  = true
  }
}

# Analytics Rule
resource "azurerm_sentinel_alert_rule_scheduled" "suspicious_resource_creation" {
  name                       = "suspicious-resource-creation"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  display_name              = "Suspicious number of resource creation or deployment"
  severity                  = "Medium"
  query                     = <<QUERY
AzureActivity
| where ResourceProviderValue =~ "Microsoft.Security" 
| where OperationNameValue =~ "Microsoft.Security/locations/jitNetworkAccessPolicies/delete"
QUERY
  query_frequency           = "PT5M"
  query_period             = "PT5M"
}

# Logic App (Playbook)
resource "azurerm_logic_app_workflow" "change_severity" {
  name                = "Change-Incident-Severity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Virtual Machine for JIT testing
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  subnet {
    name           = "mySubnet"
    address_prefix = "192.168.1.0/24"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "myVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size              = "Standard_DS2_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "myVM"
    admin_username = "azureuser"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {
    enable_automatic_updates = true
    provision_vm_agent      = true
  }
}

# Data source for current subscription
data "azurerm_subscription" "current" {}