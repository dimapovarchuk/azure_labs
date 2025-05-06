# Configure required providers and backend
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
  }

  backend "azurerm" {
    resource_group_name  = "az104-rg0"
    storage_account_name = "tfstate4c2114e0
    container_name      = "tfstate"
    key                 = "terraform.tfstate"
  }
}

# Configure Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# Generate random string for storage account name
resource "random_string" "storage_account_name" {
  length  = 8
  special = false
  upper   = false
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "lab08${random_string.storage_account_name.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  account_tier            = var.storage_account_tier
  account_replication_type = var.storage_account_replication

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create Storage Container
resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location           = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

# Create Network Interface for VM1
resource "azurerm_network_interface" "nic1" {
  name                = "vm1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create Network Interface for VM2
resource "azurerm_network_interface" "nic2" {
  name                = "vm2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create VM1
resource "azurerm_windows_virtual_machine" "vm1" {
  name                = var.vm_name1
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.vm_username
  admin_password      = var.vm_password
  zone                = 1
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create VM2
resource "azurerm_windows_virtual_machine" "vm2" {
  name                = var.vm_name2
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.vm_username
  admin_password      = var.vm_password
  zone                = 2
  network_interface_ids = [
    azurerm_network_interface.nic2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create VMSS
resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                = var.vm_size
  instances          = var.vmss_instances
  admin_username     = var.vm_username
  admin_password     = var.vm_password
  zones              = [1, 2, 3]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.subnet.id
    }
  }

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create public IP for Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create Load Balancer
resource "azurerm_lb" "lb" {
  name                = "vmss-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }

  tags = {
    environment = "lab"
    project     = "az104-lab08"
  }
}

# Create backend address pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackEndAddressPool"
}

# Create health probe
resource "azurerm_lb_probe" "probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "ssh-running-probe"
  port            = 80
}

# Create load balancing rule
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                      = azurerm_lb_probe.probe.id
}