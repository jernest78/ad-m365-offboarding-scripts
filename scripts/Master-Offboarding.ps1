<#
.SYNOPSIS
    All-in-one offboarding: Active Directory + Exchange Online + Azure AD.
.DESCRIPTION
    Runs the full offboarding sequence across AD (disable, password reset,
    group removal), Exchange Online (shared mailbox, auto-reply, GAL,
    manager access), and Azure AD (device removal, token revocation), with a
    full transcript log for your audit trail.
.PARAMETER Username
    The sAMAccountName of the user to offboard.
.PARAMETER ManagerEmail
    Primary SMTP address of the manager who should receive mailbox access.
.EXAMPLE
    .\Master-Offboarding.ps1 -Username "jsmith" -ManagerEmail "mjones@company.com"
.NOTES
    !! DEPRECATION WARNING !!
    The Azure AD section uses the deprecated AzureAD module - see
    Cleanup-AzureADDevices.ps1 for details and plan a Microsoft Graph migration.

    If a step fails mid-run, the account can be left partially offboarded
    (e.g. disabled in AD but mailbox still active). Review the transcript
    log after every run.

    From the ADATT offboarding scripts collection.
    Guide: https://adatt.unifosec.com/blog/powershell-scripts-ad-offboarding
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$ManagerEmail
)

$LogPath = "C:\Logs\Offboarding_$Username_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
Start-Transcript -Path $LogPath

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  MASTER OFFBOARDING SCRIPT" -ForegroundColor Cyan
Write-Host "  User: $Username" -ForegroundColor Cyan
Write-Host "  Date: $(Get-Date)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# SECTION 1: Active Directory
Write-Host "SECTION 1: Active Directory" -ForegroundColor Yellow
Import-Module ActiveDirectory

$ADUser = Get-ADUser -Identity $Username -Properties *
$UserEmail = $ADUser.EmailAddress

Disable-ADAccount -Identity $Username
Write-Host "  Account disabled" -ForegroundColor Green

$NewPassword = ConvertTo-SecureString (-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 20 | % {[char]$_})) -AsPlainText -Force
Set-ADAccountPassword -Identity $Username -NewPassword $NewPassword -Reset
Write-Host "  Password reset" -ForegroundColor Green

$Groups = Get-ADUser -Identity $Username -Properties MemberOf | Select -ExpandProperty MemberOf
foreach ($Group in $Groups) {
    if ($Group -notlike "*Domain Users*") {
        Remove-ADGroupMember -Identity $Group -Members $Username -Confirm:$false
    }
}
Write-Host "  Removed from $($Groups.Count - 1) groups" -ForegroundColor Green

# SECTION 2: Exchange Online
Write-Host "`nSECTION 2: Exchange Online" -ForegroundColor Yellow
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false

Set-Mailbox -Identity $UserEmail -Type Shared
Write-Host "  Mailbox converted to shared" -ForegroundColor Green

Set-MailboxAutoReplyConfiguration -Identity $UserEmail -AutoReplyState Enabled -InternalMessage "This employee is no longer with the company." -ExternalMessage "This employee is no longer with the company."
Write-Host "  Auto-reply configured" -ForegroundColor Green

Set-Mailbox -Identity $UserEmail -HiddenFromAddressListsEnabled $true
Write-Host "  Hidden from GAL" -ForegroundColor Green

Add-MailboxPermission -Identity $UserEmail -User $ManagerEmail -AccessRights FullAccess -InheritanceType All
Write-Host "  Manager granted access" -ForegroundColor Green

Disconnect-ExchangeOnline -Confirm:$false

# SECTION 3: Azure AD
Write-Host "`nSECTION 3: Azure AD & Devices" -ForegroundColor Yellow
Import-Module AzureAD
Connect-AzureAD

$AzureUser = Get-AzureADUser -ObjectId $UserEmail
$Devices = Get-AzureADUserRegisteredDevice -ObjectId $AzureUser.ObjectId

foreach ($Device in $Devices) {
    Remove-AzureADDevice -ObjectId $Device.ObjectId
}
Write-Host "  Removed $($Devices.Count) devices" -ForegroundColor Green

Revoke-AzureADUserAllRefreshToken -ObjectId $AzureUser.ObjectId
Write-Host "  Refresh tokens revoked" -ForegroundColor Green

Disconnect-AzureAD

# COMPLETION
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  OFFBOARDING COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "User: $Username ($UserEmail)"
Write-Host "Manager: $ManagerEmail"
Write-Host "Log saved to: $LogPath"
Write-Host "`nREMINDER: Remove Microsoft 365 license in 24-48 hours`n"

Stop-Transcript
