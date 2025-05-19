#!/bin/bash

# Script for Lab 02a - Manage Subscriptions and RBAC

# Set error handling
set -e
set -o pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success${NC}"
    else
        echo -e "${RED}Failed${NC}"
        exit 1
    fi
}

# Check if az cli is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if logged in to Azure
echo -e "${YELLOW}Checking Azure login status...${NC}"
az account show &> /dev/null || {
    echo -e "${YELLOW}Not logged in. Logging in to Azure...${NC}"
    az login
}

# Get current context
echo -e "${YELLOW}Getting current context...${NC}"
CURRENT_ACCOUNT=$(az account show --query user.name -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}Current context: $CURRENT_ACCOUNT on subscription $SUBSCRIPTION_NAME${NC}"

# Configuration variables
SUBSCRIPTION_SCOPE="/subscriptions/$SUBSCRIPTION_ID"
CUSTOM_ROLE_NAME="Custom Support Request"
HELPDESK_GROUP_NAME="helpdesk"

# Create custom role
echo -e "\n${YELLOW}Creating custom role...${NC}"

# Check if role exists and remove it
if az role definition list --name "$CUSTOM_ROLE_NAME" &> /dev/null; then
    echo -e "${YELLOW}Removing existing role...${NC}"
    az role definition delete --name "$CUSTOM_ROLE_NAME"
    echo "Waiting for role deletion to propagate..."
    sleep 30
fi

# Create role definition JSON
echo -e "${YELLOW}Creating role definition...${NC}"
cat > custom-role.json << EOF
{
    "Name": "$CUSTOM_ROLE_NAME",
    "Description": "Custom role for support requests",
    "Actions": [
        "Microsoft.Resources/subscriptions/*/read",
        "Microsoft.Support/*"
    ],
    "NotActions": [
        "Microsoft.Support/register/action"
    ],
    "AssignableScopes": [
        "$SUBSCRIPTION_SCOPE"
    ]
}
EOF

# Create new role
echo -e "${YELLOW}Creating new role...${NC}"
az role definition create --role-definition custom-role.json
check_status

echo -e "${YELLOW}Waiting for role to propagate...${NC}"
sleep 30

# Create helpdesk group
echo -e "\n${YELLOW}Creating helpdesk group...${NC}"

# Check if group exists
GROUP_ID=$(az ad group list --display-name "$HELPDESK_GROUP_NAME" --query '[0].id' -o tsv)

if [ -z "$GROUP_ID" ]; then
    echo -e "${YELLOW}Creating new helpdesk group...${NC}"
    GROUP_ID=$(az ad group create \
        --display-name "$HELPDESK_GROUP_NAME" \
        --mail-nickname "helpdesk" \
        --description "Helpdesk support group" \
        --query id -o tsv)
    check_status
else
    echo -e "${YELLOW}Helpdesk group already exists${NC}"
fi

# Assign roles
if [ ! -z "$GROUP_ID" ]; then
    echo -e "\n${YELLOW}Assigning roles...${NC}"
    
    # Assign VM Contributor role
    echo "Assigning VM Contributor role..."
    az role assignment create \
        --assignee-object-id "$GROUP_ID" \
        --assignee-principal-type Group \
        --role "Virtual Machine Contributor" \
        --scope "$SUBSCRIPTION_SCOPE"
    check_status

    echo -e "${YELLOW}Waiting between role assignments...${NC}"
    sleep 30

    # Assign custom support role
    echo "Assigning custom support role..."
    az role assignment create \
        --assignee-object-id "$GROUP_ID" \
        --assignee-principal-type Group \
        --role "$CUSTOM_ROLE_NAME" \
        --scope "$SUBSCRIPTION_SCOPE"
    check_status
fi

# Verify role assignments
echo -e "\n${YELLOW}Verifying role assignments...${NC}"
echo -e "${GREEN}Current role assignments:${NC}"
az role assignment list \
    --assignee-object-id "$GROUP_ID" \
    --query "[?roleDefinitionName=='$CUSTOM_ROLE_NAME' || roleDefinitionName=='Virtual Machine Contributor'].{Principal:principalName, Role:roleDefinitionName, Scope:scope}" \
    --output table

# Display summary
echo -e "\n${GREEN}Summary:${NC}"
echo "1. Custom Role: $CUSTOM_ROLE_NAME"
if [ ! -z "$GROUP_ID" ]; then
    echo "2. Helpdesk Group: $HELPDESK_GROUP_NAME (ID: $GROUP_ID)"
    echo "3. Role Assignments: VM Contributor and $CUSTOM_ROLE_NAME"
else
    echo "2. Helpdesk Group: Not created"
fi

# Display current custom roles
echo -e "\n${YELLOW}Current custom roles:${NC}"
az role definition list \
    --custom-role-only true \
    --query "[].{Name:roleName, Description:description}" \
    --output table

# Cleanup temporary files
rm -f custom-role.json

echo -e "\n${GREEN}Deployment completed successfully${NC}"

# Save deployment information for cleanup
cat > deployment-info.json << EOF
{
    "subscriptionId": "$SUBSCRIPTION_ID",
    "customRoleName": "$CUSTOM_ROLE_NAME",
    "helpdeskGroupName": "$HELPDESK_GROUP_NAME",
    "helpdeskGroupId": "$GROUP_ID"
}
EOF

echo -e "${YELLOW}Deployment information saved to deployment-info.json${NC}"
