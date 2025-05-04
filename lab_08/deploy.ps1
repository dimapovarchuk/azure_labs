#!/usr/bin/env pwsh

# Credentials variables
$vmUsername = "localadmin"
$vmPassword = "P@ssw0rd1234!"
$securePassword = ConvertTo-SecureString $vmPassword -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ($vmUsername, $securePassword)

# Check Azure connection
try {
    Get-AzContext
}
catch {
    Write-Host "No Azure connection detected. Connecting..." -ForegroundColor Yellow
    Connect-AzAccount -UseDeviceAuthentication
}

# Variables
$resourceGroup = "az104-rg8"
$location = "eastus"
$vmName1 = "az104-vm1"
$vmName2 = "az104-vm2"
$vnetName = "myVNet"
$subnetName = "default"
$vmSize = "Standard_D2s_v3"

# Create Resource Group
Write-Host "Creating Resource Group..." -ForegroundColor Green
New-AzResourceGroup -Name $resourceGroup -Location $location

# Create Virtual Network
Write-Host "Creating Virtual Network..." -ForegroundColor Green
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24"
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
    -Name $vnetName -AddressPrefix "10.0.0.0/16" -Subnet $subnetConfig

# VM1 in Zone 1
Write-Host "Creating VM1 in Zone 1..." -ForegroundColor Green
New-AzVM -ResourceGroupName $resourceGroup -Location $location -Name $vmName1 `
    -VirtualNetworkName $vnetName -SubnetName $subnetName -Zone 1 `
    -Image "Win2019Datacenter" -Size $vmSize -Credential $credentials

# VM2 in Zone 2
Write-Host "Creating VM2 in Zone 2..." -ForegroundColor Green
New-AzVM -ResourceGroupName $resourceGroup -Location $location -Name $vmName2 `
    -VirtualNetworkName $vnetName -SubnetName $subnetName -Zone 2 `
    -Image "Win2019Datacenter" -Size $vmSize -Credential $credentials

# Create VMSS
Write-Host "Creating VM Scale Set..." -ForegroundColor Green
$vmssName = "vmss1"

New-AzVmss -ResourceGroupName $resourceGroup -VMScaleSetName $vmssName -Location $location `
    -VirtualNetworkName "vmss-vnet" -SubnetName "subnet0" -PublicIpAddressName "vmss-pip" `
    -LoadBalancerName "vmss-lb" -UpgradePolicyMode "Automatic" `
    -Zone @('1','2','3') -Credential $credentials -VMSize "Standard_D2s_v3" `
    -ImageName "Win2019Datacenter"

Write-Host "Deployment completed successfully!" -ForegroundColor Green

# Display resource information
Write-Host "`nDeployment Summary:" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup"
Write-Host "VMs: $vmName1, $vmName2"
Write-Host "VMSS: $vmssName"
Write-Host "Username: $vmUsername"
Write-Host "Password: $vmPassword"
Write-Host "`nNote: Please save these credentials in a secure location." -ForegroundColor Yellow
