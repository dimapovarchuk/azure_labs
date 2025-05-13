#!/bin/bash

# Variables
RESOURCE_GROUP="TestRG"
LOCATION="eastus"
STORAGE_NAME="mystorageacc123xyz"
POLICY_NAME="deny-storage-accounts"
ASSIGNMENT_NAME="deny-storage-policy-assignment"

echo "Starting resource creation process..."

# 1. Create Resource Group
echo "Creating Resource Group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# 2. Create Storage Account
echo "Creating Storage Account..."
az storage account create \
    --name $STORAGE_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS

# 3. Create Policy Definition
echo "Creating Policy Definition..."
cat << EOF > deny-storage-policy.json
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
EOF

az policy definition create \
    --name $POLICY_NAME \
    --display-name "Deny storage accounts" \
    --description "This policy denies creation of storage accounts" \
    --rules deny-storage-policy.json \
    --mode All

# 4. Assign Policy
echo "Assigning Policy..."
az policy assignment create \
    --name $ASSIGNMENT_NAME \
    --policy $POLICY_NAME \
    --resource-group $RESOURCE_GROUP

echo "Resource creation completed!"
