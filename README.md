# KINDL Regional IT Support Toolkit

A portfolio project simulating the IT support and system administration work needed to roll out a new statewide system (modeled on KYTC's KINDL platform) across regional driver licensing offices.

## Why this exists

Rolling out a new system across dozens of regional offices isn't just a software deployment — it's an operational challenge: new accounts need provisioning, permissions need to be right on day one, field offices need fast troubleshooting, and every step needs to be documented for audit and handoff. This repo simulates the toolkit and workflows a regional IT support specialist would use to keep that rollout running smoothly.

## What's included

| Folder | Purpose |
|---|---|
| `scripts/` | PowerShell scripts for common Windows sysadmin tasks: account provisioning/deprovisioning, connectivity testing, system health checks, and software inventory |
| `access-management/` | A role-based permissions matrix and an access-request log template for tracking who has access to what, and why |
| `docs/` | A security and documentation practices guide covering patching cadence, least-privilege access, and incident documentation |

## Scenario this models

A new system (KINDL) is rolling out region by region to driver licensing offices. Each go-live requires:
1. Provisioning accounts for new/transferred staff with the correct role and access level
2. Verifying network connectivity and system health at the office before go-live
3. Fast, well-documented troubleshooting during and after cutover
4. A clean audit trail of who has access to what, and a process for revoking it when staff leave or transfer

## Notes

These scripts are written to run against a Windows/Active Directory environment (they reference the `ActiveDirectory` PowerShell module). They're structured and commented as production-style templates — swap in real domain/OU details to adapt them to a live environment.

## Author

Jonik Patel — MIS/MBA dual master's, KYTC Data Analyst internship alum. Background in data systems and analytics; built this toolkit to demonstrate readiness to support DDL's regional offices through the KINDL transition.
