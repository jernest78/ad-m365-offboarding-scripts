<#
.SYNOPSIS
    Basic Active Directory account disable for employee offboarding.
.DESCRIPTION
    Disables the user account, resets the password to a random value,
    stamps the description with the termination date, and logs the action.
.PARAMETER Username
    The sAMAccountName of the user to offboard.
.EXAMPLE
    .\Disable-ADUser.ps1 -Username "jsmith"
.NOTES
    From the ADATT offboarding scripts collection.
    Guide: https://adatt.unifosec.com/blog/powershell-scripts-ad-offboarding
    Test on a non-production account first.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)

# Import AD Module
Import-Module ActiveDirectory

# Get current date
$Date = Get-Date -Format "yyyy-MM-dd"

# Generate random password
$NewPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})
$SecurePassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force

try {
    # Disable account
    Disable-ADAccount -Identity $Username
    Write-Host "Account disabled: $Username" -ForegroundColor Green

    # Reset password
    Set-ADAccountPassword -Identity $Username -NewPassword $SecurePassword -Reset
    Write-Host "Password reset for: $Username" -ForegroundColor Green

    # Update description
    Set-ADUser -Identity $Username -Description "Terminated: $Date"
    Write-Host "Description updated: $Username" -ForegroundColor Green

    # Log action
    $LogEntry = "$Date - $Username disabled by $env:USERNAME"
    Add-Content -Path "C:\Logs\AD_Terminations.log" -Value $LogEntry

    Write-Host "`nOffboarding completed for: $Username" -ForegroundColor Cyan
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
