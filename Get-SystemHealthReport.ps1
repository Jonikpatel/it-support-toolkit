<#
.SYNOPSIS
    Pulls a quick health snapshot of a workstation — disk space, memory, pending reboots,
    and Windows Update status — for fast triage on a support ticket.

.DESCRIPTION
    Meant to be the first thing run against a machine when a ticket comes in ("system is
    slow", "can't install update", etc.) so the tech has a baseline before digging further.
    Can be run locally or against a remote computer with -ComputerName.

.PARAMETER ComputerName
    Target machine. Defaults to the local machine.

.EXAMPLE
    .\Get-SystemHealthReport.ps1 -ComputerName "R12-DESK-014"
#>

param(
    [string]$ComputerName = $env:COMPUTERNAME
)

$session = if ($ComputerName -eq $env:COMPUTERNAME) { $null } else { New-CimSession -ComputerName $ComputerName }
$cimParams = if ($session) { @{ CimSession = $session } } else { @{} }

$os = Get-CimInstance -ClassName Win32_OperatingSystem @cimParams
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" @cimParams
$rebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue

Write-Host "=== System Health Report: $ComputerName ===" -ForegroundColor Cyan
Write-Host "OS: $($os.Caption) (Build $($os.BuildNumber))"
Write-Host "Last Boot: $($os.LastBootUpTime)"
Write-Host "Reboot Pending: $rebootPending"
Write-Host ""

Write-Host "Free Memory: $([math]::Round($os.FreePhysicalMemory / 1MB, 2)) GB of $([math]::Round($os.TotalVisibleMemorySize / 1MB, 2)) GB"
Write-Host ""

Write-Host "Disk Space:"
$disk | ForEach-Object {
    $freePct = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
    $flag = if ($freePct -lt 10) { " <-- LOW SPACE" } else { "" }
    Write-Host ("  {0}: {1} GB free of {2} GB ({3}% free){4}" -f `
        $_.DeviceID, [math]::Round($_.FreeSpace / 1GB, 1), [math]::Round($_.Size / 1GB, 1), $freePct, $flag)
}

if ($session) { Remove-CimSession $session }
