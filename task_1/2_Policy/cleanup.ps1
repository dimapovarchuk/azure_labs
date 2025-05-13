# Variables
$resourceGroup = "TestRG"
$storageName = "mystorageacc123xyz"
$policyName = "deny-storage-accounts"
$assignmentName = "deny-storage-policy-assignment"

Write-Host "Starting cleanup process..." -ForegroundColor Yellow

# 1. Remove Policy Assignment
Write-Host "Removing Policy Assignment..." -ForegroundColor Cyan
try {
    Remove-AzPolicyAssignment `
        -Name $assignmentName `
        -Scope (Get-AzResourceGroup -Name $resourceGroup).ResourceId `
        -ErrorAction Stop
    Write-Host "Policy Assignment removed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to remove Policy Assignment" -ForegroundColor Red
}

# 2. Remove Policy Definition
Write-Host "Removing Policy Definition..." -ForegroundColor Cyan
try {
    Remove-AzPolicyDefinition `
        -Name $policyName `
        -Force `
        -ErrorAction Stop
    Write-Host "Policy Definition removed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to remove Policy Definition" -ForegroundColor Red
}

# 3. Remove Storage Account
Write-Host "Removing Storage Account..." -ForegroundColor Cyan
try {
    Remove-AzStorageAccount `
        -ResourceGroupName $resourceGroup `
        -Name $storageName `
        -Force `
        -ErrorAction Stop
    Write-Host "Storage Account removed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to remove Storage Account" -ForegroundColor Red
}

# 4. Remove Resource Group
Write-Host "Removing Resource Group..." -ForegroundColor Cyan
try {
    Remove-AzResourceGroup `
        -Name $resourceGroup `
        -Force `
        -ErrorAction Stop
    Write-Host "Resource Group removed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to remove Resource Group" -ForegroundColor Red
}

Write-Host "Cleanup completed!" -ForegroundColor Yellow
