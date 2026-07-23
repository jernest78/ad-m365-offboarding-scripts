<#
.SYNOPSIS
    Bulk Active Directory offboarding from a CSV file.
.DESCRIPTION
    Reads users from a CSV (Username,TerminationDate,Manager), disables each
    account, resets passwords, removes group memberships, and exports a
    success/failure results CSV.
.PARAMETER CSVPath
    Path to the input CSV. Expected columns: Username,TerminationDate,Manager
.EXAMPLE
    .\Bulk-Offboarding.ps1 -CSVPath "C:\Temp\terminations.csv"
.NOTES
    From the ADATT offboarding scripts collection.
    Guide: https://adatt.unifosec.com/blog/powershell-scripts-ad-offboarding
    CSV format:
        Username,TerminationDate,Manager
        jsmith,2026-01-15,mjones
        bdoe,2026-01-15,sjohnson
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$CSVPath
)

Import-Module ActiveDirectory

$Users = Import-Csv $CSVPath
$Results = @()

foreach ($User in $Users) {
    $Status = @{
        Username = $User.Username
        TerminationDate = $User.TerminationDate
        Success = $false
        Error = ""
    }

    try {
        # Disable account
        Disable-ADAccount -Identity $User.Username

        # Reset password
        $NewPass = ConvertTo-SecureString (-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | % {[char]$_})) -AsPlainText -Force
        Set-ADAccountPassword -Identity $User.Username -NewPassword $NewPass -Reset

        # Remove from groups
        $Groups = Get-ADUser -Identity $User.Username -Properties MemberOf | Select -ExpandProperty MemberOf
        foreach ($Group in $Groups) {
            if ($Group -notlike "*Domain Users*") {
                Remove-ADGroupMember -Identity $Group -Members $User.Username -Confirm:$false
            }
        }

        $Status.Success = $true
        Write-Host "[OK] $($User.Username) - Completed" -ForegroundColor Green
    }
    catch {
        $Status.Error = $_.Exception.Message
        Write-Host "[FAIL] $($User.Username) - $($Status.Error)" -ForegroundColor Red
    }

    $Results += New-Object PSObject -Property $Status
}

# Export results
$Results | Export-Csv "C:\Logs\BulkOffboarding-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" -NoTypeInformation

Write-Host "`n=========================================="
Write-Host "Bulk offboarding completed!"
Write-Host "Total: $($Users.Count) | Success: $(($Results | Where {$_.Success}).Count) | Failed: $(($Results | Where {-not $_.Success}).Count)"
