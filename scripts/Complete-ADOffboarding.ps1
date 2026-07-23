<#
.SYNOPSIS
    Complete Active Directory offboarding: disable, groups, OU move, GAL, expiration.
.DESCRIPTION
    Disables the account, resets the password, removes all security groups
    (except Domain Users), clears the manager, hides the user from the Global
    Address List, moves them to a Disabled OU, sets an account expiration date,
    and exports before/after state to CSV for your audit trail.
.PARAMETER Username
    The sAMAccountName of the user to offboard.
.PARAMETER DisabledOU
    Distinguished name of the OU that holds disabled users.
.PARAMETER ExpirationDays
    Days until the disabled account expires (default 90).
.EXAMPLE
    .\Complete-ADOffboarding.ps1 -Username "jsmith" -DisabledOU "OU=Disabled Users,DC=company,DC=com"
.NOTES
    From the ADATT offboarding scripts collection.
    Guide: https://adatt.unifosec.com/blog/powershell-scripts-ad-offboarding
    Test on a non-production account first.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$false)]
    [string]$DisabledOU = "OU=Disabled Users,DC=company,DC=com",

    [Parameter(Mandatory=$false)]
    [int]$ExpirationDays = 90
)

Import-Module ActiveDirectory

$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ExpirationDate = (Get-Date).AddDays($ExpirationDays)

# Backup current state
$User = Get-ADUser -Identity $Username -Properties *
$User | Select-Object Name, SamAccountName, Enabled, DistinguishedName, MemberOf |
    Export-Csv "C:\Logs\$Username-BeforeOffboarding-$Date.csv" -NoTypeInformation

Write-Host "Starting offboarding for: $($User.Name)" -ForegroundColor Cyan
Write-Host "==========================================`n"

# Step 1: Disable account
Disable-ADAccount -Identity $Username
Write-Host "[1/7] Account disabled" -ForegroundColor Green

# Step 2: Reset password
$NewPassword = ConvertTo-SecureString (-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 20 | % {[char]$_})) -AsPlainText -Force
Set-ADAccountPassword -Identity $Username -NewPassword $NewPassword -Reset
Write-Host "[2/7] Password reset" -ForegroundColor Green

# Step 3: Remove from groups
$Groups = Get-ADUser -Identity $Username -Properties MemberOf | Select-Object -ExpandProperty MemberOf
$RemovedGroups = @()

foreach ($Group in $Groups) {
    if ($Group -notlike "*Domain Users*") {
        Remove-ADGroupMember -Identity $Group -Members $Username -Confirm:$false
        $RemovedGroups += $Group
    }
}
Write-Host "[3/7] Removed from $($RemovedGroups.Count) security groups" -ForegroundColor Green

# Step 4: Clear manager
Set-ADUser -Identity $Username -Manager $null -Clear Manager
Write-Host "[4/7] Manager relationship cleared" -ForegroundColor Green

# Step 5: Hide from GAL
Set-ADUser -Identity $Username -Replace @{msExchHideFromAddressLists=$true}
Write-Host "[5/7] Hidden from Global Address List" -ForegroundColor Green

# Step 6: Move to Disabled OU
Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU
Write-Host "[6/7] Moved to Disabled Users OU" -ForegroundColor Green

# Step 7: Set expiration date
Set-ADAccountExpiration -Identity $Username -DateTime $ExpirationDate
Write-Host "[7/7] Account expiration set to: $($ExpirationDate.ToString('yyyy-MM-dd'))" -ForegroundColor Green

# Update description
$Description = "Terminated: $Date by $env:USERNAME"
Set-ADUser -Identity $Username -Description $Description

# Export final state
Get-ADUser -Identity $Username -Properties * |
    Select-Object Name, SamAccountName, Enabled, DistinguishedName, AccountExpirationDate |
    Export-Csv "C:\Logs\$Username-AfterOffboarding-$Date.csv" -NoTypeInformation

Write-Host "`n=========================================="
Write-Host "Offboarding completed successfully!" -ForegroundColor Green
Write-Host "User: $($User.Name)"
Write-Host "Groups removed: $($RemovedGroups.Count)"
Write-Host "Expires on: $($ExpirationDate.ToString('yyyy-MM-dd'))"
Write-Host "`nLogs saved to: C:\Logs\"
