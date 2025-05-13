# Variables
$resourceGroup = "TestRG"
$location = "eastus"
$storageName = "mystorageacc123xyz"

Write-Host "1. Creating Resources..." -ForegroundColor Green

# Create Resource Group
New-AzResourceGroup `
    -Name $resourceGroup `
    -Location $location

# Create Storage Account
New-AzStorageAccount `
    -ResourceGroupName $resourceGroup `
    -Name $storageName `
    -Location $location `
    -SkuName Standard_LRS

Write-Host "2. Listing Resources..." -ForegroundColor Green

# List Resource Group
Write-Host "Resource Group Details:" -ForegroundColor Yellow
Get-AzResourceGroup -Name $resourceGroup

# List Storage Account
Write-Host "Storage Account Details:" -ForegroundColor Yellow
Get-AzStorageAccount `
    -ResourceGroupName $resourceGroup `
    -Name $storageName

# List all resources in Resource Group
Write-Host "All Resources in Group:" -ForegroundColor Yellow
Get-AzResource -ResourceGroupName $resourceGroup

Write-Host "3. Deleting Resources..." -ForegroundColor Green

# Delete Storage Account
Remove-AzStorageAccount `
    -ResourceGroupName $resourceGroup `
    -Name $storageName `
    -Force

# Delete Resource Group
Remove-AzResourceGroup `
    -Name $resourceGroup `
    -Force