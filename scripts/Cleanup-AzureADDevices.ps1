<#
.SYNOPSIS
    Azure AD (Entra ID) device removal, token revocation, and MFA reset.
.DESCRIPTION
    Lists and removes the user's registered Azure AD devices, revokes all
    refresh tokens, and resets MFA registration.
.PARAMETER UserPrincipalName
    UPN of the departing user.
.EXAMPLE
    .\Cleanup-AzureADDevices.ps1 -UserPrincipalName "jsmith@company.com"
.NOTES
    !! DEPRECATION WARNING !!
    This script uses the AzureAD and MSOnline modules, which Microsoft has
    deprecated and retired in favor of Microsoft Graph PowerShell. It is kept
    here because many environments still have these modules installed, but you
    should plan a migration to Microsoft.Graph (Connect-MgGraph) equivalents.
    This maintenance burden is exactly why dedicated tools exist - see
    https://adatt.unifosec.com/vs/powershell-scripts

    From the ADATT offboarding scripts collection.
    Guide: https://adatt.unifosec.com/blog/powershell-scripts-ad-offboarding
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName
)

# Install module if not present
if (-not (Get-Module -ListAvailable -Name AzureAD)) {
    Install-Module AzureAD -Force -AllowClobber
}

Import-Module AzureAD
Connect-AzureAD

$User = Get-AzureADUser -ObjectId $UserPrincipalName

Write-Host "Processing Azure AD cleanup for: $($User.DisplayName)" -ForegroundColor Cyan

# Step 1: Get and remove devices
$Devices = Get-AzureADUserRegisteredDevice -ObjectId $User.ObjectId
Write-Host "`n[1/3] Found $($Devices.Count) registered devices" -ForegroundColor Yellow

foreach ($Device in $Devices) {
    Remove-AzureADDevice -ObjectId $Device.ObjectId
    Write-Host "  Removed: $($Device.DisplayName)" -ForegroundColor Green
}

# Step 2: Revoke refresh tokens
Revoke-AzureADUserAllRefreshToken -ObjectId $User.ObjectId
Write-Host "[2/3] All refresh tokens revoked" -ForegroundColor Green

# Step 3: Reset MFA (requires admin consent; uses deprecated MSOnline module)
$MFAMethods = Get-MsolUser -UserPrincipalName $UserPrincipalName | Select-Object -ExpandProperty StrongAuthenticationMethods
if ($MFAMethods) {
    Reset-MsolStrongAuthenticationMethodByUpn -UserPrincipalName $UserPrincipalName
    Write-Host "[3/3] MFA registration reset" -ForegroundColor Green
} else {
    Write-Host "[3/3] No MFA methods found" -ForegroundColor Yellow
}

Write-Host "`nAzure AD cleanup completed!" -ForegroundColor Green

Disconnect-AzureAD
