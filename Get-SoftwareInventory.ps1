<#
.SYNOPSIS
    Exports a list of installed software on a workstation to CSV — useful for confirming
    KINDL client prerequisites are present before go-live, or auditing what's installed
    across an office's machines.

.PARAMETER ComputerName
    Target machine. Defaults to the local machine.

.PARAMETER OutputPath
    Where to write the CSV. Defaults to a timestamped file in the current directory.

.EXAMPLE
    .\Get-SoftwareInventory.ps1 -ComputerName "R12-DESK-014" -OutputPath "R12-DESK-014-software.csv"
#>

param(
    [string]$ComputerName = $env:COMPUTERNAME,
    [string]$OutputPath = "software-inventory-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

$scriptBlock = {
    Get-ItemProperty @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    ) -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
}

$inventory = if ($ComputerName -eq $env:COMPUTERNAME) {
    & $scriptBlock
} else {
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock
}

$inventory | Sort-Object DisplayName | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "Exported $($inventory.Count) installed applications from $ComputerName to $OutputPath" -ForegroundColor Green

# Quick check for a required KINDL prerequisite as an example — swap in real requirements.
$requiredApp = "KINDL Client"
if (-not ($inventory | Where-Object { $_.DisplayName -like "*$requiredApp*" })) {
    Write-Host "WARNING: '$requiredApp' not found on $ComputerName — this machine is not ready for go-live." -ForegroundColor Red
}
