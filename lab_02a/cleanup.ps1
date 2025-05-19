# Cleanup Script for Lab 02a

# First, let's check your permissions
Write-Host "Checking current permissions..." -ForegroundColor Yellow
$context = Get-AzContext
Write-Host "Current context: $($context.Account) on subscription $($context.Subscription.Name)" -ForegroundColor Green

# Configuration variables
$subscriptionId = $context.Subscription.Id
$subscriptionScope = "/subscriptions/$subscriptionId"
$customRoleName = "Custom Support Request"
$helpdeskGroupName = "helpdesk"

# Remove role assignments
Write-Host "`nRemoving role assignments..." -ForegroundColor Yellow
try {
    $group = Get-AzADGroup -DisplayName $helpdeskGroupName -ErrorAction SilentlyContinue
    if ($group) {
        # Remove VM Contributor role
        Remove-AzRoleAssignment -ObjectId $group.Id `
            -RoleDefinitionName "Virtual Machine Contributor" `
            -Scope $subscriptionScope -ErrorAction SilentlyContinue
        Write-Host "VM Contributor role assignment removed" -ForegroundColor Green

        # Remove custom role
        Remove-AzRoleAssignment -ObjectId $group.Id `
            -RoleDefinitionName $customRoleName `
            -Scope $subscriptionScope -ErrorAction SilentlyContinue
        Write-Host "Custom role assignment removed" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error removing role assignments: $_" -ForegroundColor Red
}

# Remove custom role
Write-Host "`nRemoving custom role..." -ForegroundColor Yellow
try {
    $role = Get-AzRoleDefinition -Name $customRoleName -ErrorAction SilentlyContinue
    if ($role) {
        Remove-AzRoleDefinition -Id $role.Id -Force
        Write-Host "Custom role removed" -ForegroundColor Green
    } else {
        Write-Host "Custom role not found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error removing custom role: $_" -ForegroundColor Red
}

# Remove helpdesk group
Write-Host "`nRemoving helpdesk group..." -ForegroundColor Yellow
try {
    if ($group) {
        Remove-AzADGroup -ObjectId $group.Id -Force
        Write-Host "Helpdesk group removed" -ForegroundColor Green
    } else {
        Write-Host "Helpdesk group not found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error removing helpdesk group: $_" -ForegroundColor Red
}

# Verify cleanup
Write-Host "`nVerifying cleanup..." -ForegroundColor Yellow

# Check role
$roleExists = Get-AzRoleDefinition -Name $customRoleName -ErrorAction SilentlyContinue
if ($roleExists) {
    Write-Host "Warning: Custom role still exists" -ForegroundColor Red
} else {
    Write-Host "Custom role removed successfully" -ForegroundColor Green
}

# Check group
$groupExists = Get-AzADGroup -DisplayName $helpdeskGroupName -ErrorAction SilentlyContinue
if ($groupExists) {
    Write-Host "Warning: Helpdesk group still exists" -ForegroundColor Red
} else {
    Write-Host "Helpdesk group removed successfully" -ForegroundColor Green
}

Write-Host "`nCleanup completed" -ForegroundColor Green

