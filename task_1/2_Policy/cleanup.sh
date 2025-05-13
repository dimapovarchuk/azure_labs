#!/bin/bash

# Variables
RESOURCE_GROUP="TestRG"
STORAGE_NAME="mystorageacc123xyz"
POLICY_NAME="deny-storage-accounts"
ASSIGNMENT_NAME="deny-storage-policy-assignment"

echo "Starting cleanup process..."

# 1. Remove Policy Assignment
echo "Removing Policy Assignment..."
az policy assignment delete \
    --name $ASSIGNMENT_NAME \
    --resource-group $RESOURCE_GROUP

# 2. Remove Policy Definition
echo "Removing Policy Definition..."
az policy definition delete \
    --name $POLICY_NAME

# 3. Remove Storage Account
echo "Removing Storage Account..."
az storage account delete \
    --name $STORAGE_NAME \
    --resource-group $RESOURCE_GROUP \
    --yes

# 4. Remove Resource Group
echo "Removing Resource Group..."
az group delete \
    --name $RESOURCE_GROUP \
    --yes

echo "Cleanup completed!"
