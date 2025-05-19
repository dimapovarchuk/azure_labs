#!/bin/bash

# Cleanup Script for Lab 02a

# Set error handling
set -e
set -o pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check current context
echo -e "${YELLOW}Checking current permissions...${NC}"
CURRENT_ACCOUNT=$(az account show --query user.name -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}Current context: $CURRENT_ACCOUNT on subscription $SUBSCRIPTION_NAME${NC}"

# Configuration variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_SCOPE="/subscriptions/$SUBSCRIPTION_ID"
CUSTOM_ROLE_NAME="Custom Support Request"
HELPDESK_GROUP_NAME="helpdesk"

# Get group ID
GROUP_ID=$(az ad group list --display-name "$HELPDESK_GROUP_NAME" --query '[0].id' -o tsv)

# Remove role assignments
echo -e "\n${YELLOW}Removing role assignments...${NC}"
if [ ! -z "$GROUP_ID" ]; then
    # Remove VM Contributor role
    az role assignment delete \
        --assignee-object-id "$GROUP_ID" \
        --role "Virtual Machine Contributor" \
        --scope "$SUBSCRIPTION_SCOPE" \
        2>/dev/null || echo -e "${YELLOW}VM Contributor role assignment not found${NC}"

    # Remove custom role
    az role assignment delete \
        --assignee-object-id "$GROUP_ID" \
        --role "$CUSTOM_ROLE_NAME" \
        --scope "$SUBSCRIPTION_SCOPE" \
        2>/dev/null || echo -e "${YELLOW}Custom role assignment not found${NC}"
    
    echo -e "${GREEN}Role assignments removed${NC}"
fi

# Remove custom role
echo -e "\n${YELLOW}Removing custom role...${NC}"
az role definition delete --name "$CUSTOM_ROLE_NAME" 2>/dev/null || \
    echo -e "${YELLOW}Custom role not found${NC}"
echo -e "${GREEN}Custom role removed${NC}"

# Remove helpdesk group
echo -e "\n${YELLOW}Removing helpdesk group...${NC}"
if [ ! -z "$GROUP_ID" ]; then
    az ad group delete --group "$GROUP_ID" 2>/dev/null || \
        echo -e "${YELLOW}Helpdesk group not found${NC}"
    echo -e "${GREEN}Helpdesk group removed${NC}"
fi

# Verify cleanup
echo -e "\n${YELLOW}Verifying cleanup...${NC}"

# Check role
if az role definition list --name "$CUSTOM_ROLE_NAME" >/dev/null 2>&1; then
    echo -e "${RED}Warning: Custom role still exists${NC}"
else
    echo -e "${GREEN}Custom role removed successfully${NC}"
fi

# Check group
if az ad group list --display-name "$HELPDESK_GROUP_NAME" --query '[0].id' -o tsv >/dev/null 2>&1; then
    echo -e "${RED}Warning: Helpdesk group still exists${NC}"
else
    echo -e "${GREEN}Helpdesk group removed successfully${NC}"
fi

echo -e "\n${GREEN}Cleanup completed${NC}"
