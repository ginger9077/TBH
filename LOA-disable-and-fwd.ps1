try {
    Import-Module AzureAD -ErrorAction Stop
    Import-Module ActiveDirectory -ErrorAction Stop
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
} catch {
    Write-Output "Missing pre-req modules"
}

#
# https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/remove-former-employee?view=o365-worldwide
#
# Step 0 - Connect to AzureAD
function Connect {
    $connectionName = "AzureRunAsConnection"
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    Connect-AzureAD -TenantID $servicePrincipalConnection.TenantID -ApplicationId $servicePrincipalConnection.ApplicationId  -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
    
    # tbh-automation-exo application registration: https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/bdeb7efa-a9bd-4b31-9505-bb112b4d5a3f/isMSAApp~/false
    Connect-ExchangeOnline -CertificateThumbPrint "9ECB35CB6B25549473DEC2AAEA271E50E10FD16B" -AppId "bdeb7efa-a9bd-4b31-9505-bb112b4d5a3f" -Organization "therapybrands.onmicrosoft.com"
}

# Step 1 - Prevent a former employee from logging in and block access to Microsoft 365 services	
#
#          This blocks your former employee from logging in to Microsoft 365 
#          and prevents the person from accessing Microsoft 365 services.
function Block-Access-User {
    param (
        [String] $username
    )
    # Disable AD account and AAD account
    Disable-ADAccount -Identity $username -Confirm:$false
    Set-AzureADUser -ObjectId "$username@therapybrands.com" -AccountEnabled $false

    # Invalidate application refresh tokens
    $userid = (Get-AzureADUser -ObjectId "$username@therapybrands.com").ObjectId
    Revoke-AzureADUserAllRefreshToken -ObjectId $userid
return;
}
Set-Mailbox $username@therapybrands.com -ForwardingAddress $fwdemailaddress -DeliverToMailboxAndForward $True