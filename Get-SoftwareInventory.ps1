<#
.SYNOPSIS
    Pulls installed software from a local or remote workstation to CSV.
    Used for pre-cutover readiness audits and verifying KINDL prerequisites.

.DESCRIPTION
    Queries both 64-bit and 32-bit registry uninstall paths via WinRM / local registry.
    Outputs cleaned inventory to CSV and flags missing baseline applications.

.PARAMETER ComputerName
    Target endpoint hostname or IP. Defaults to localhost.

.PARAMETER OutputPath
    Destination file path for the CSV report.

.EXAMPLE
    .\Get-SoftwareInventory.ps1 -ComputerName "R12-DESK-014"
#>

[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [string]$ComputerName = $env:COMPUTERNAME,

    [Parameter(Position = 1)]
    [string]$OutputPath = ".\Inventory-$($ComputerName)-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
)

begin {
    Write-Verbose "Starting software inventory check on target: $ComputerName"
    
    # Prerequisite software required before go-live
    $RequiredSoftware = "KINDL Client"

    $AuditScript = {
        $RegPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        Get-ItemProperty -Path $RegPaths -ErrorAction SilentlyContinue |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_.DisplayName) } |
            Select-Object @{Name = 'ComputerName'; Expression = { $env:COMPUTERNAME }},
                          DisplayName,
                          DisplayVersion,
                          Publisher,
                          InstallDate
    }
}

process {
    try {
        if ($ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq 'localhost') {
            $results = & $AuditScript
        } else {
            # Test connectivity before invoking remote session
            if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
                throw "Unable to reach $ComputerName via ICMP. Endpoint may be offline."
            }
            $results = Invoke-Command -ComputerName $ComputerName -ScriptBlock $AuditScript -ErrorAction Stop
        }

        if ($results) {
            $sortedResults = $results | Sort-Object DisplayName
            $sortedResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            
            Write-Host "[OK] Exported $($sortedResults.Count) application(s) from $ComputerName -> $OutputPath" -ForegroundColor Green

            # Verify go-live prerequisite
            $hasPrereq = $sortedResults | Where-Object { $_.DisplayName -like "*$RequiredSoftware*" }
            if (-not $hasPrereq) {
                Write-Warning "Missing prerequisite: '$RequiredSoftware' was not detected on $ComputerName. Workstation is NOT ready for cutover."
            } else {
                Write-Host "[OK] Baseline check passed: '$RequiredSoftware' is installed." -ForegroundColor Cyan
            }
        } else {
            Write-Warning "No installed applications found or insufficient permissions on $ComputerName."
        }
    }
    catch {
        Write-Error "Failed to collect software inventory from $ComputerName. Reason: $($_.Exception.Message)"
    }
}
