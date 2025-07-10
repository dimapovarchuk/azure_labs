# Provider configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data source for current subscription
data "azurerm_subscription" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "AZ500LAB131415"
  location = "East US"
}

# Random string for unique naming
resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "sentinel-workspace-${random_string.random.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                = "PerGB2018"
  retention_in_days   = 30
}

# Microsoft Sentinel Solution
resource "azurerm_log_analytics_solution" "sentinel" {
  solution_name         = "SecurityInsights"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name       = azurerm_log_analytics_workspace.law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}

# Microsoft Sentinel Onboarding
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel_onboarding" {
  workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on   = [azurerm_log_analytics_solution.sentinel]
}

# Wait for Sentinel to be fully deployed
resource "time_sleep" "wait_30_seconds" {
  depends_on = [
    azurerm_log_analytics_solution.sentinel,
    azurerm_sentinel_log_analytics_workspace_onboarding.sentinel_onboarding
  ]
  create_duration = "30s"
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
  
  depends_on = [
    time_sleep.wait_30_seconds,
    azurerm_sentinel_log_analytics_workspace_onboarding.sentinel_onboarding
  ]
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNICConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.pip.id
  }
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "myNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "myVM"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_DS2_v2"
  admin_username      = "azureuser"
  admin_password      = "Password1234!"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Logic App (Playbook)
resource "azurerm_logic_app_workflow" "change_severity" {
  name                = "Change-Incident-Severity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Diagnostic Setting for Activity Logs
resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  name                       = "activity-logs-sentinel"
  target_resource_id         = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "Administrative"
  }
  enabled_log {
    category = "Security"
  }
  enabled_log {
    category = "ServiceHealth"
  }
  enabled_log {
    category = "Alert"
  }
  enabled_log {
    category = "Recommendation"
  }
  enabled_log {
    category = "Policy"
  }
  enabled_log {
    category = "Autoscale"
  }
  enabled_log {
    category = "ResourceHealth"
  }
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "vm_public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "workspace_name" {
  value = azurerm_log_analytics_workspace.law.name
}