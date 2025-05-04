#!/usr/bin/env pwsh

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

# Confirmation request
Write-Host "`nWARNING!" -ForegroundColor Red
Write-Host "This will delete ALL resources in the resource group: $resourceGroup" -ForegroundColor Yellow
$confirmation = Read-Host "`nAre you sure you want to proceed? (Y/N)"

if ($confirmation -eq 'Y') {
    Write-Host "`nStarting resource cleanup..." -ForegroundColor Yellow
    
    try {
        # Delete resource group and all resources within it
        Write-Host "Deleting resource group: $resourceGroup"
        Remove-AzResourceGroup -Name $resourceGroup -Force
        Write-Host "`nResources deleted successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "`nError during cleanup: $_" -ForegroundColor Red
        Write-Host "Please check Azure Portal for more details." -ForegroundColor Yellow
    }
}
else {
    Write-Host "`nOperation cancelled by user" -ForegroundColor Yellow
}

Write-Host "`nScript completed" -ForegroundColor Green
