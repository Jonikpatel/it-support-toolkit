<#
.SYNOPSIS
    Provisions a new Active Directory user account for a regional driver licensing office,
    assigns them to the correct security groups based on role, and logs the action.

.DESCRIPTION
    Designed for onboarding staff during a phased system rollout (e.g. KINDL go-live) across
    multiple regional offices. Takes a role name and maps it to the correct group memberships,
    so access is consistent office-to-office instead of being configured ad hoc.

.PARAMETER FirstName
    New user's first name.

.PARAMETER LastName
    New user's last name.

.PARAMETER OfficeCode
    Short code identifying the regional office (e.g. "R12" for Region 12). Used to place the
    account in the correct OU and to tag the access log.

.PARAMETER Role
    One of: "FrontDeskClerk", "OfficeSupervisor", "ITSupport", "RegionalAdmin".
    Determines which security groups the account is added to.

.EXAMPLE
    .\New-UserAccount.ps1 -FirstName "Alex" -LastName "Rivera" -OfficeCode "R12" -Role "FrontDeskClerk"
#>

param(
    [Parameter(Mandatory = $true)][string]$FirstName,
    [Parameter(Mandatory = $true)][string]$LastName,
    [Parameter(Mandatory = $true)][string]$OfficeCode,
    [Parameter(Mandatory = $true)]
    [ValidateSet("FrontDeskClerk", "OfficeSupervisor", "ITSupport", "RegionalAdmin")]
    [string]$Role
)

Import-Module ActiveDirectory

# Role -> security group mapping. Keeping this in one place means every office
# provisions accounts with identical, predictable access instead of one-off permissions.
$roleGroupMap = @{
    "FrontDeskClerk"   = @("KINDL-Users", "OfficePrinters")
    "OfficeSupervisor" = @("KINDL-Users", "OfficePrinters", "KINDL-Supervisors")
    "ITSupport"        = @("KINDL-Users", "KINDL-ITSupport", "HelpdeskTools")
    "RegionalAdmin"    = @("KINDL-Users", "KINDL-Supervisors", "KINDL-RegionalAdmins")
}

$samAccountName = ("{0}.{1}" -f $FirstName, $LastName).ToLower()
$userPrincipalName = "$samAccountName@ddl.ky.gov"
$targetOU = "OU=$OfficeCode,OU=RegionalOffices,DC=ddl,DC=ky,DC=gov"

try {
    New-ADUser `
        -Name "$FirstName $LastName" `
        -GivenName $FirstName `
        -Surname $LastName `
        -SamAccountName $samAccountName `
        -UserPrincipalName $userPrincipalName `
        -Path $targetOU `
        -Enabled $true `
        -ChangePasswordAtLogon $true `
        -AccountPassword (ConvertTo-SecureString "TempPass!2026" -AsPlainText -Force)

    foreach ($group in $roleGroupMap[$Role]) {
        Add-ADGroupMember -Identity $group -Members $samAccountName
    }

    # Log every provisioning action for the access-review audit trail (see access-management/).
    $logEntry = [PSCustomObject]@{
        Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Action      = "ProvisionAccount"
        User        = $samAccountName
        Office      = $OfficeCode
        Role        = $Role
        GroupsAdded = ($roleGroupMap[$Role] -join "; ")
    }
    $logEntry | Export-Csv -Path "..\access-management\access-request-log.csv" -Append -NoTypeInformation

    Write-Host "Provisioned account '$samAccountName' for $Role at office $OfficeCode." -ForegroundColor Green
}
catch {
    Write-Error "Failed to provision account for $FirstName $LastName : $_"
}
