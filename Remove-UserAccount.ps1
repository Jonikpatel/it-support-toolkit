<#
.SYNOPSIS
    Deprovisions an Active Directory account (staff departure or transfer), removing group
    memberships and disabling the account rather than deleting it outright.

.DESCRIPTION
    Disabling instead of deleting preserves the audit trail and avoids orphaning any files
    or tickets tied to the account's SID. Every deprovisioning action is logged to the same
    access-request-log.csv used by New-UserAccount.ps1, so the log always shows a full
    lifecycle (grant -> revoke) for every account.

.PARAMETER SamAccountName
    The account's logon name (e.g. "alex.rivera").

.PARAMETER Reason
    Short reason for the record: "Departure", "Transfer", or "RoleChange".

.EXAMPLE
    .\Remove-UserAccount.ps1 -SamAccountName "alex.rivera" -Reason "Transfer"
#>

param(
    [Parameter(Mandatory = $true)][string]$SamAccountName,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Departure", "Transfer", "RoleChange")]
    [string]$Reason
)

Import-Module ActiveDirectory

try {
    $user = Get-ADUser -Identity $SamAccountName -Properties MemberOf
    $groups = $user.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }

    foreach ($group in $groups) {
        Remove-ADGroupMember -Identity $group -Members $SamAccountName -Confirm:$false
    }

    Disable-ADAccount -Identity $SamAccountName

    $logEntry = [PSCustomObject]@{
        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Action        = "DeprovisionAccount"
        User          = $SamAccountName
        Reason        = $Reason
        GroupsRemoved = ($groups -join "; ")
    }
    $logEntry | Export-Csv -Path "..\access-management\access-request-log.csv" -Append -NoTypeInformation

    Write-Host "Deprovisioned account '$SamAccountName' (reason: $Reason)." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to deprovision account $SamAccountName : $_"
}
