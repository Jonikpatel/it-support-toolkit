<#
.SYNOPSIS
    Deprovisions an Active Directory user account, strips non-primary security groups,
    disables the login, and logs the action for audit compliance.

.DESCRIPTION
    Executes a clean offboarding/transfer workflow for regional field staff. 
    Rather than deleting the object outright (which destroys the SID and breaks historical
    ticket/file auditing), this script revokes all active group memberships, moves or
    disables the user account, and appends a record to the shared access-request-log.csv.

.PARAMETER SamAccountName
    The target user's logon name (e.g., 'alex.rivera').

.PARAMETER Reason
    Operational reason for offboarding: Departure, Transfer, or RoleChange.

.EXAMPLE
    .\Remove-UserAccount.ps1 -SamAccountName "alex.rivera" -Reason "Departure"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SamAccountName,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet("Departure", "Transfer", "RoleChange")]
    [string]$Reason
)

# Relative path to central audit log
$LogPath = Join-Path -Path $PSScriptRoot -ChildPath "..\access-management\access-request-log.csv"

try {
    # Check for ActiveDirectory RSAT module
    if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
        throw "Active Directory PowerShell module is required but not installed."
    }
    Import-Module ActiveDirectory -ErrorAction Stop

    # Locate user and enumerate existing group memberships
    $user = Get-ADUser -Identity $SamAccountName -Properties MemberOf, PrimaryGroup -ErrorAction Stop
    
    if (-not $user) {
        throw "User account '$SamAccountName' could not be found."
    }

    # Identify removable groups (excludes 'Domain Users' / primary group)
    $groupsToRemove = @()
    if ($user.MemberOf) {
        $groupsToRemove = $user.MemberOf | ForEach-Object {
            (Get-ADGroup -Identity $_).Name
        }
    }

    Write-Verbose "Processing deprovisioning for: $SamAccountName (Reason: $Reason)"

    # Strip assigned security groups
    if ($groupsToRemove.Count -gt 0) {
        foreach ($group in $groupsToRemove) {
            if ($PSCmdlet.ShouldProcess("$SamAccountName", "Remove from group '$group'")) {
                Remove-ADGroupMember -Identity $group -Members $SamAccountName -Confirm:$false -ErrorAction Stop
                Write-Verbose "Removed $SamAccountName from group: $group"
            }
        }
    } else {
        Write-Verbose "No secondary security groups found for $SamAccountName."
    }

    # Disable the Active Directory account
    if ($PSCmdlet.ShouldProcess("$SamAccountName", "Disable AD account")) {
        Disable-ADAccount -Identity $SamAccountName -ErrorAction Stop
        
        # Optional: Set a note in the description field with timestamp and reason
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Set-ADUser -Identity $SamAccountName -Description "Disabled by $env:USERNAME on $timestamp - Reason: $Reason" -ErrorAction SilentlyContinue
    }

    # Ensure log directory exists before appending
    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Record action in audit log
    $logEntry = [PSCustomObject]@{
        Timestamp     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Action        = "DeprovisionAccount"
        SamAccount    = $SamAccountName
        Reason        = $Reason
        GroupsRemoved = ($groupsToRemove -join "; ")
        ExecutedBy    = $env:USERNAME
    }

    $logEntry | Export-Csv -Path $LogPath -Append -NoTypeInformation -Encoding UTF8

    Write-Host "[OK] Account '$SamAccountName' successfully disabled and stripped of permissions (Reason: $Reason)." -ForegroundColor Yellow
}
catch {
    Write-Error "[ERROR] Failed to deprovision account '$SamAccountName'. Details: $($_.Exception.Message)"
}
