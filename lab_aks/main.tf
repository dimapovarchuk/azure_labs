terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "resource_group_name" {
  default = "AZ500LAB09"
}

variable "location" {
  default = "eastus"
}

variable "cluster_name" {
  default = "MyKubernetesCluster"
}

variable "acr_name" {
  default = "acr500lab09" # Має бути глобально унікальним
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "lab"
    project     = "AZ500LAB09"
  }
}

# ACR (Azure Container Registry)
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  sku                = "Basic"
  admin_enabled      = false
  
  tags = {
    environment = "lab"
    project     = "AZ500LAB09"
  }
}

# AKS (Azure Kubernetes Service)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks500lab09"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  tags = {
    environment = "lab"
    project     = "AZ500LAB09"
  }
}

# Role Assignment для доступу AKS до ACR
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# External Nginx Deployment
resource "kubernetes_deployment" "nginx_external" {
  metadata {
    name = "nginxexternal"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginxexternal"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginxexternal"
        }
      }

      spec {
        container {
          image = "${azurerm_container_registry.acr.login_server}/nginx:v1"
          name  = "nginx"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.aks_acr]
}

# External Service (LoadBalancer)
resource "kubernetes_service" "nginx_external" {
  metadata {
    name = "nginxexternal"
  }

  spec {
    selector = {
      app = "nginxexternal"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.nginx_external]
}

# Internal Nginx Deployment
resource "kubernetes_deployment" "nginx_internal" {
  metadata {
    name = "nginxinternal"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginxinternal"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginxinternal"
        }
      }

      spec {
        container {
          image = "${azurerm_container_registry.acr.login_server}/nginx:v1"
          name  = "nginx"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.aks_acr]
}

# Internal Service (ClusterIP)
resource "kubernetes_service" "nginx_internal" {
  metadata {
    name = "nginxinternal"
  }

  spec {
    selector = {
      app = "nginxinternal"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.nginx_internal]
}

# Outputs
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "external_ip" {
  value = kubernetes_service.nginx_external.status.0.load_balancer.0.ingress.0.ip
}

output "internal_ip" {
  value = kubernetes_service.nginx_internal.spec.0.cluster_ip
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}