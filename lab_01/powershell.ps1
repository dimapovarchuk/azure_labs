# Connect to Azure AD
Connect-AzureAD

# Variables
$userUPN = "az104-user1@yourdomain.com"
$userDisplayName = "az104-user1"
$password = ConvertTo-SecureString (New-Guid).Guid -AsPlainText -Force
$groupName = "IT Lab Administrators"
$guestEmail = "guest@example.com"

# 1. Create new user
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = $password
$PasswordProfile.ForceChangePasswordNextLogin = $true

New-AzureADUser `
    -DisplayName $userDisplayName `
    -UserPrincipalName $userUPN `
    -PasswordProfile $PasswordProfile `
    -AccountEnabled $true `
    -MailNickName "az104-user1" `
    -JobTitle "IT Lab Administrator" `
    -Department "IT"

# 2. Invite external user
New-AzureADMSInvitation `
    -InvitedUserEmailAddress $guestEmail `
    -InvitedUserDisplayName "Guest User" `
    -InviteRedirectUrl "https://portal.azure.com" `
    -SendInvitationMessage $true `
    -MessageInfo "Welcome to Azure and our group project"

# 3. Create security group
New-AzureADGroup `
    -DisplayName $groupName `
    -MailEnabled $false `
    -SecurityEnabled $true `
    -Description "Administrators that manage the IT lab" `
    -MailNickName "itlabadmin"

# 4. Add users to group
$group = Get-AzureADGroup -SearchString $groupName
$user = Get-AzureADUser -ObjectId $userUPN
Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $user.ObjectId