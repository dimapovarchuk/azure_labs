#!/bin/bash

# Login to Azure
az login

# Variables
USER_UPN="az104-user1@yourdomain.com"
USER_DISPLAY_NAME="az104-user1"
USER_PASSWORD=$(openssl rand -base64 12)
GROUP_NAME="IT Lab Administrators"
GUEST_EMAIL="guest@example.com"

# 1. Create new user
echo "Creating new user..."
az ad user create \
  --display-name $USER_DISPLAY_NAME \
  --user-principal-name $USER_UPN \
  --password $USER_PASSWORD \
  --mail-nickname "az104-user1" \
  --job-title "IT Lab Administrator" \
  --department "IT" \
  --force-change-password-next-login true

# 2. Invite external user
echo "Inviting external user..."
az ad user invite \
  --email $GUEST_EMAIL \
  --display-name "Guest User" \
  --message "Welcome to Azure and our group project" \
  --redirect-url "https://portal.azure.com"

# 3. Create security group
echo "Creating security group..."
az ad group create \
  --display-name "$GROUP_NAME" \
  --mail-nickname "itlabadmin" \
  --description "Administrators that manage the IT lab"

# 4. Add users to group
echo "Adding users to group..."
az ad group member add --group "$GROUP_NAME" --member-id $(az ad user show --id $USER_UPN --query objectId -o tsv)