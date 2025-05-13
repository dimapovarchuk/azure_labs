# Variables
$resourceGroup = "TestRG"
$location = "eastus"
$storageName = "mystorageacc123xyz"
$policyName = "deny-storage-accounts"
$assignmentName = "deny-storage-policy-assignment"

Write-Host "Starting resource creation process..." -ForegroundColor Yellow

# 1. Create Resource Group
Write-Host "Creating Resource Group..." -ForegroundColor Cyan
New-AzResourceGroup -Name $resourceGroup -Location $location

# 2. Create Storage Account
Write-Host "Creating Storage Account..." -ForegroundColor Cyan
New-AzStorageAccount `
    -ResourceGroupName $resourceGroup `
    -Name $storageName `
    -Location $location `
    -SkuName Standard_LRS `
    -Kind StorageV2

# 3. Create Policy Definition
Write-Host "Creating Policy Definition..." -ForegroundColor Cyan
$policyRule = @"
{
    "if": {
        "allOf": [
            {
                "field": "type",
                "equals": "Microsoft.Storage/storageAccounts"
            }
        ]
    },
    "then": {
        "effect": "deny"
    }
}
"@

$policy = New-AzPolicyDefinition `
    -Name $policyName `
    -DisplayName "Deny storage accounts" `
    -Description "This policy denies creation of storage accounts" `
    -Policy $policyRule `
    -Mode All

# 4. Assign Policy
Write-Host "Assigning Policy..." -ForegroundColor Cyan
New-AzPolicyAssignment `
    -Name $assignmentName `
    -PolicyDefinition $policy `
    -Scope (Get-AzResourceGroup -Name $resourceGroup).ResourceId

Write-Host "Resource creation completed!" -ForegroundColor Green
