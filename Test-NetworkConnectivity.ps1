<#
.SYNOPSIS
    Runs a set of network connectivity checks against critical endpoints required
    for regional office operations and KINDL go-live readiness.

.DESCRIPTION
    Validates DNS resolution, ICMP reachability (ping), and target TCP port connectivity
    across core services (KINDL application server, Active Directory domain controller, 
    and network print server). 
    
    Outputs a clean console summary and returns diagnostic objects to help field technicians 
    quickly isolate whether an issue is local (workstation/switch) or upstream (WAN link/firewall).

.PARAMETER AppServer
    Hostname or FQDN/IP of the core KINDL application server.

.PARAMETER DomainController
    Hostname or FQDN/IP of the regional/primary domain controller.

.PARAMETER PrintServer
    Hostname or FQDN/IP of the local or centralized branch print server.

.PARAMETER PortTimeoutSec
    Timeout in seconds for TCP port connection tests (default: 3 seconds).

.EXAMPLE
    .\Test-NetworkConnectivity.ps1 -AppServer "kindl-app01.ddl.ky.gov" -DomainController "dc-r12.ddl.ky.gov" -PrintServer "print-r12.ddl.ky.gov"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$AppServer,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$DomainController,

    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [string]$PrintServer,

    [Parameter(Position = 3)]
    [int]$PortTimeoutSec = 3
)

begin {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host " REGIONAL NETWORK CONNECTIVITY AUDIT" -ForegroundColor Cyan
    Write-Host " Source Host: $env:COMPUTERNAME | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "========================================================`n" -ForegroundColor Cyan

    $targets = @(
        [PSCustomObject]@{ Role = "KINDL App Server" ; Hostname = $AppServer        ; Port = 443  ; Description = "HTTPS / Web UI" },
        [PSCustomObject]@{ Role = "Domain Controller"; Hostname = $DomainController ; Port = 389  ; Description = "LDAP / AD Auth" },
        [PSCustomObject]@{ Role = "Print Server"     ; Hostname = $PrintServer      ; Port = 9100 ; Description = "RAW Print Queue" }
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
}

process {
    foreach ($target in $targets) {
        Write-Verbose "Testing target: $($target.Role) ($($target.Hostname):$($target.Port))"

        # 1. DNS Resolution Check
        $dnsPassed = $false
        $resolvedIP = "Unresolved"
        try {
            $dnsLookup = [System.Net.Dns]::GetHostEntry($target.Hostname)
            $resolvedIP = ($dnsLookup.AddressList | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1).IPAddressToString
            if ([string]::IsNullOrWhiteSpace($resolvedIP)) {
                $resolvedIP = $dnsLookup.AddressList[0].IPAddressToString
            }
            $dnsPassed = $true
        } catch {
            $dnsPassed = $false
        }

        # 2. ICMP Ping Check
        $pingPassed = Test-Connection -ComputerName $target.Hostname -Count 2 -Quiet -ErrorAction SilentlyContinue

        # 3. TCP Port Connectivity Check (with customizable timeout)
        $tcpPassed = $false
        if ($dnsPassed) {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            try {
                $asyncConnect = $tcpClient.BeginConnect($target.Hostname, $target.Port, $null, $null)
                $success = $asyncConnect.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds($PortTimeoutSec))

                if ($success -and $tcpClient.Connected) {
                    $tcpPassed = $true
                    $tcpClient.EndConnect($asyncConnect)
                }
            } catch {
                $tcpPassed = $false
            } finally {
                $tcpClient.Close()
                $tcpClient.Dispose()
            }
        }

        # Determine Overall Status
        $overallStatus = if ($dnsPassed -and $tcpPassed) { "PASS" } else { "FAIL" }

        # Output readable status line to console
        $color = if ($overallStatus -eq "PASS") { "Green" } else { "Red" }
        Write-Host "[$overallStatus] " -NoNewline -ForegroundColor $color
        Write-Host "$($target.Role.PadRight(18)) " -NoNewline -ForegroundColor White
        Write-Host "-> $($target.Hostname) ($resolvedIP)"

        Write-Host "       DNS: " -NoNewline
        Write-Host ($(if ($dnsPassed) { "OK" } else { "FAILED" })) -NoNewline -ForegroundColor $(if ($dnsPassed) { "Green" } else { "Red" })
        Write-Host " | ICMP: " -NoNewline
        Write-Host ($(if ($pingPassed) { "OK" } else { "NO RESPONSE" })) -NoNewline -ForegroundColor $(if ($pingPassed) { "Green" } else { "Yellow" })
        Write-Host " | Port $($target.Port) ($($target.Description)): " -NoNewline
        Write-Host ($(if ($tcpPassed) { "OPEN" } else { "BLOCKED/CLOSED" })) -ForegroundColor $(if ($tcpPassed) { "Green" } else { "Red" })
        Write-Host ""

        # Collect structured result
        $results.Add([PSCustomObject]@{
            Role          = $target.Role
            TargetHost    = $target.Hostname
            ResolvedIP    = $resolvedIP
            TargetPort    = $target.Port
            DNSResolution = $dnsPassed
            PingSuccess   = $pingPassed
            PortOpen      = $tcpPassed
            OverallStatus = $overallStatus
        })
    }
}

end {
    $failedChecks = $results | Where-Object { $_.OverallStatus -eq "FAIL" }
    
    if ($failedChecks.Count -gt 0) {
        Write-Warning "Audit finished with $($failedChecks.Count) service failure(s). Check local firewall, routing, or branch switch."
    } else {
        Write-Host "All core network dependencies are reachable. Ready for office cutover.`n" -ForegroundColor Green
    }

    # Pass object collection down pipeline for logging/export if needed
    return $results
}
