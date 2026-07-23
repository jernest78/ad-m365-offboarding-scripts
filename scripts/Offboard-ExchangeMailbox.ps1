<#
.SYNOPSIS
    Exchange Online mailbox offboarding: convert to shared, auto-reply, GAL, permissions.
.DESCRIPTION
    Connects to Exchange Online, converts the user's mailbox to a shared
    mailbox, configures an auto-reply, hides the mailbox from the Global
    Address List, and grants the manager Full Access + Send As.
.PARAMETER UserEmail
    Primary SMTP address of the departing user.
.PARAMETER ManagerEmail
    Primary SMTP address of the manager who should receive access.
.PARAMETER AutoReplyMessage
    Auto-reply text set for internal and external senders.
.EXAMPLE
    .\Offboard-ExchangeMailbox.ps1 -UserEmail "jsmith@company.com" -ManagerEmail "mjones@company.com"
.NOTES
    Requires the ExchangeOnlineManagement module (Install-Module ExchangeOnlineManagement).
    From the ADATT offboarding scripts collection.
    Guide: https://adatt.unifosec.com/blog/powershell-scripts-ad-offboarding
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$UserEmail,

    [Parameter(Mandatory=$true)]
    [string]$ManagerEmail,

    [Parameter(Mandatory=$false)]
    [string]$AutoReplyMessage = "Thank you for your email. This employee is no longer with the company. For assistance, please contact HR at hr@company.com"
)

# Connect to Exchange Online (requires Exchange Online Management module)
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

Write-Host "Processing mailbox: $UserEmail" -ForegroundColor Cyan

try {
    # Step 1: Convert to shared mailbox
    Set-Mailbox -Identity $UserEmail -Type Shared
    Write-Host "[1/4] Converted to shared mailbox" -ForegroundColor Green

    # Step 2: Set auto-reply
    Set-MailboxAutoReplyConfiguration -Identity $UserEmail -AutoReplyState Enabled -InternalMessage $AutoReplyMessage -ExternalMessage $AutoReplyMessage
    Write-Host "[2/4] Auto-reply message configured" -ForegroundColor Green

    # Step 3: Hide from GAL
    Set-Mailbox -Identity $UserEmail -HiddenFromAddressListsEnabled $true
    Write-Host "[3/4] Hidden from Global Address List" -ForegroundColor Green

    # Step 4: Grant manager Full Access and Send As
    Add-MailboxPermission -Identity $UserEmail -User $ManagerEmail -AccessRights FullAccess -InheritanceType All
    Add-RecipientPermission -Identity $UserEmail -Trustee $ManagerEmail -AccessRights SendAs -Confirm:$false
    Write-Host "[4/4] Permissions granted to: $ManagerEmail" -ForegroundColor Green

    Write-Host "`nMailbox offboarding completed!" -ForegroundColor Green
    Write-Host "Note: Wait 24-48 hours before removing Microsoft 365 license"
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Disconnect-ExchangeOnline -Confirm:$false
