<#
.SYNOPSIS
    Gathers a rapid system health snapshot (OS details, uptime, pending reboots, 
    memory utilization, and disk capacity) for initial ticket triage.

.DESCRIPTION
    Designed as a first-response triage tool when a ticket reports slowness,
    patching issues, or general instability. Can be run locally or against a 
    remote machine over WinRM / CIM.

.PARAMETER ComputerName
    Target machine name or IP address. Defaults to the local host.

.EXAMPLE
    .\Get-SystemHealthReport.ps1 -ComputerName "R12-DESK-014"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [string]$ComputerName = $env:COMPUTERNAME
)

begin {
    Write-Verbose "Querying system health metrics for target: $ComputerName"
}

process {
    $isLocal = ($ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq 'localhost' -or $ComputerName -eq '127.0.0.1')
    $session = $null

    try {
        if (-not $isLocal) {
            # Quick connectivity check before initiating CIM session
            if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
                throw "Host $ComputerName is offline or unreachable over ICMP."
            }
            $session = New-CimSession -ComputerName $ComputerName -ErrorAction Stop
            $cimParams = @{ CimSession = $session }
        } else {
            $cimParams = @{}
        }

        # Query OS and Memory information
        $os = Get-CimInstance -ClassName Win32_OperatingSystem @cimParams -ErrorAction Stop
        
        # Calculate memory metrics
        $totalMemGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeMemGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedMemGB  = [math]::Round($totalMemGB - $freeMemGB, 2)
        $memUsedPct = [math]::Round(($usedMemGB / $totalMemGB) * 100, 1)

        # Query Fixed Disks
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" @cimParams -ErrorAction Stop

        # Check for pending reboot (remote-safe via CIM/Registry query)
        $rebootPending = $false
        $regCheckBlock = {
            $wu = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
            $cbs = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
            (Test-Path $wu) -or (Test-Path $cbs)
        }

        if ($isLocal) {
            $rebootPending = & $regCheckBlock
        } else {
            $rebootPending = Invoke-Command -CimSession $session -ScriptBlock $regCheckBlock -ErrorAction SilentlyContinue
            if ($null -eq $rebootPending) { $rebootPending = $false }
        }

        # Output Summary
        Write-Host "`n========================================================" -ForegroundColor Cyan
        Write-Host " SYSTEM HEALTH REPORT: $($ComputerName.ToUpper())" -ForegroundColor Cyan
        Write-Host "========================================================" -ForegroundColor Cyan
        
        Write-Host "OS Version      : $($os.Caption) (Build $($os.BuildNumber))"
        Write-Host "Last Boot Time  : $($os.LastBootUpTime)"
        
        if ($rebootPending) {
            Write-Host "Pending Reboot  : " -NoNewline
            Write-Host "YES (Reboot Required)" -ForegroundColor Yellow
        } else {
            Write-Host "Pending Reboot  : No"
        }

        Write-Host "Memory Usage    : $usedMemGB GB / $totalMemGB GB ($memUsedPct% in use)"

        Write-Host "`nDisk Storage:"
        foreach ($d in $disks) {
            if ($d.Size -gt 0) {
                $totalDiskGB = [math]::Round($d.Size / 1GB, 1)
                $freeDiskGB  = [math]::Round($d.FreeSpace / 1GB, 1)
                $freePct     = [math]::Round(($d.FreeSpace / $d.Size) * 100, 1)

                $diskLine = "  [{0}] {1} GB free of {2} GB ({3}% free)" -f $d.DeviceID, $freeDiskGB, $totalDiskGB, $freePct

                if ($freePct -lt 10) {
                    Write-Host "$diskLine <-- CRITICAL: LOW DISK SPACE" -ForegroundColor Red
                } elseif ($freePct -lt 15) {
                    Write-Host "$diskLine <-- WARNING: Low Space" -ForegroundColor Yellow
                } else {
                    Write-Host $diskLine
                }
            }
        }
        Write-Host ""
    }
    catch {
        Write-Error "Failed to retrieve health metrics from $ComputerName. Details: $($_.Exception.Message)"
    }
    finally {
        if ($session) {
            Remove-CimSession $session -ErrorAction SilentlyContinue
        }
    }
}
