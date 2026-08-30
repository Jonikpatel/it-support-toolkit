<#
.SYNOPSIS
    Runs a set of connectivity checks against the systems a regional office needs reachable
    before a KINDL go-live (or during day-to-day troubleshooting).

.DESCRIPTION
    Checks basic reachability (ping), DNS resolution, and port connectivity to the core
    application server, domain controller, and print server. Outputs a pass/fail summary
    so field support can quickly tell whether an issue is local (workstation) or upstream
    (WAN link, server-side).

.PARAMETER AppServer
    Hostname or IP of the KINDL application server.

.PARAMETER DomainController
    Hostname or IP of the office's domain controller.

.PARAMETER PrintServer
    Hostname or IP of the office's print server.

.EXAMPLE
    .\Test-NetworkConnectivity.ps1 -AppServer "kindl-app01.ddl.ky.gov" -DomainController "dc-r12.ddl.ky.gov" -PrintServer "print-r12.ddl.ky.gov"
#>

param(
    [Parameter(Mandatory = $true)][string]$AppServer,
    [Parameter(Mandatory = $true)][string]$DomainController,
    [Parameter(Mandatory = $true)][string]$PrintServer
)

$targets = @(
    @{ Name = "KINDL App Server"; Host = $AppServer; Port = 443 },
    @{ Name = "Domain Controller"; Host = $DomainController; Port = 389 },
    @{ Name = "Print Server";      Host = $PrintServer;      Port = 9100 }
)

$results = foreach ($target in $targets) {
    $pingOk = Test-Connection -ComputerName $target.Host -Count 2 -Quiet
    $portOk = $false
    if ($pingOk) {
        $portOk = (Test-NetConnection -ComputerName $target.Host -Port $target.Port -WarningAction SilentlyContinue).TcpTestSucceeded
    }

    [PSCustomObject]@{
        System        = $target.Name
        Host          = $target.Host
        PingReachable = $pingOk
        PortReachable = $portOk
        Status        = if ($pingOk -and $portOk) { "OK" } elseif ($pingOk) { "PORT BLOCKED" } else { "UNREACHABLE" }
    }
}

$results | Format-Table -AutoSize

$failures = $results | Where-Object { $_.Status -ne "OK" }
if ($failures) {
    Write-Host "`n$($failures.Count) system(s) failed connectivity checks — escalate before go-live." -ForegroundColor Red
} else {
    Write-Host "`nAll systems reachable. Office is clear for go-live." -ForegroundColor Green
}
