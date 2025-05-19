# Script for Lab 02a - Manage Subscriptions and RBAC

# First, let's check your permissions
Write-Host "Checking current permissions..." -ForegroundColor Yellow
$context = Get-AzContext
Write-Host "Current context: $($context.Account) on subscription $($context.Subscription.Name)" -ForegroundColor Green

# Configuration variables
$subscriptionId = $context.Subscription.Id
$subscriptionScope = "/subscriptions/$subscriptionId"
$customRoleName = "Custom Support Request"

# Create custom role
Write-Host "Creating custom role..." -ForegroundColor Green
try {
    # First, try to remove existing role if it exists
    $existingRole = Get-AzRoleDefinition -Name $customRoleName -ErrorAction SilentlyContinue
    if ($existingRole) {
        Write-Host "Removing existing role..." -ForegroundColor Yellow
        Remove-AzRoleDefinition -Id $existingRole.Id -Force -Scope $subscriptionScope
        Start-Sleep -Seconds 30
    }

    # Create new role based on Support Request Contributor
    $role = Get-AzRoleDefinition "Support Request Contributor"
    $role.Id = $null
    $role.Name = $customRoleName
    $role.Description = "Custom role for support requests"
    $role.Actions.Clear()
    $role.Actions.Add("Microsoft.Resources/subscriptions/*/read")
    $role.Actions.Add("Microsoft.Support/*")
    $role.NotActions.Add("Microsoft.Support/register/action")
    $role.AssignableScopes.Clear()
    $role.AssignableScopes.Add($subscriptionScope)

    Write-Host "Creating new role..." -ForegroundColor Yellow
    $newRole = New-AzRoleDefinition -Role $role
    
    Write-Host "Waiting for role to propagate..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    Write-Host "Custom role created successfully" -ForegroundColor Green
}
catch {
    Write-Host "Error creating custom role: $_" -ForegroundColor Red
}

# Create helpdesk group
Write-Host "`nCreating helpdesk group..." -ForegroundColor Green
try {
    $helpdeskGroupName = "helpdesk"
    $group = Get-AzADGroup -DisplayName $helpdeskGroupName -ErrorAction SilentlyContinue

    if (-not $group) {
        $group = New-AzADGroup -DisplayName $helpdeskGroupName `
                              -MailNickname $helpdeskGroupName.ToLower() `
                              -Description "Helpdesk support group"
        Write-Host "Helpdesk group created successfully" -ForegroundColor Green
    }
    else {
        Write-Host "Helpdesk group already exists" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error creating group: $_" -ForegroundColor Red
    Write-Host "Please create the group manually in Azure Portal:" -ForegroundColor Yellow
    Write-Host "1. Go to Azure Active Directory" -ForegroundColor Yellow
    Write-Host "2. Select Groups" -ForegroundColor Yellow
    Write-Host "3. Click New Group" -ForegroundColor Yellow
    Write-Host "4. Create a Security group named 'helpdesk'" -ForegroundColor Yellow
}

# Assign roles if group exists
if ($group) {
    Write-Host "`nAssigning roles..." -ForegroundColor Green
    try {
        # Assign VM Contributor role
        New-AzRoleAssignment -ObjectId $group.Id `
            -RoleDefinitionName "Virtual Machine Contributor" `
            -Scope $subscriptionScope

        Write-Host "Waiting between role assignments..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30

        # Assign custom support role
        New-AzRoleAssignment -ObjectId $group.Id `
            -RoleDefinitionName $customRoleName `
            -Scope $subscriptionScope

        Write-Host "Roles assigned successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error assigning roles: $_" -ForegroundColor Red
    }
}

# Verify role assignments
Write-Host "`nVerifying role assignments..." -ForegroundColor Green
Get-AzRoleAssignment | Where-Object {
    $_.RoleDefinitionName -eq $customRoleName -or 
    $_.RoleDefinitionName -eq "Virtual Machine Contributor"
} | Format-Table DisplayName, RoleDefinitionName, Scope

Write-Host "`nScript completed" -ForegroundColor Green

# Display summary
Write-Host "`nSummary:" -ForegroundColor Green
Write-Host "1. Custom Role: $customRoleName"
if ($group) {
    Write-Host "2. Helpdesk Group: $($group.DisplayName) (ID: $($group.Id))"
    Write-Host "3. Role Assignments: VM Contributor and $customRoleName"
} else {
    Write-Host "2. Helpdesk Group: Not created (please create manually)"
}

# Display current roles
Write-Host "`nCurrent custom roles:" -ForegroundColor Green
Get-AzRoleDefinition | Where-Object { $_.IsCustom -eq $true } | Format-Table Name, Description