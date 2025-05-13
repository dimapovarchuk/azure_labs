#!/bin/bash

# Variables
RESOURCE_GROUP="TestRG"
LOCATION="eastus"
STORAGE_NAME="mystorageacc123xyz"

echo "1. Creating Resources..."
# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Storage Account
az storage account create \
    --name $STORAGE_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS

echo "2. Listing Resources..."
# List Resource Group
echo "Resource Group Details:"
az group show --name $RESOURCE_GROUP

# List Storage Account
echo "Storage Account Details:"
az storage account show \
    --name $STORAGE_NAME \
    --resource-group $RESOURCE_GROUP

# List all resources in Resource Group
echo "All Resources in Group:"
az resource list --resource-group $RESOURCE_GROUP --output table

echo "3. Deleting Resources..."
# Delete Storage Account
az storage account delete \
    --name $STORAGE_NAME \
    --resource-group $RESOURCE_GROUP \
    --yes

# Delete Resource Group
az group delete --name $RESOURCE_GROUP --yes