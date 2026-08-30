# Security & Documentation Practices

Guidelines for keeping regional office systems secure and every support action traceable during and after the KINDL rollout.

## Access & accounts

- Provision and deprovision accounts through the standard scripts (`New-UserAccount.ps1` / `Remove-UserAccount.ps1`) so every grant/revoke is logged automatically — no manual, undocumented access changes.
- Disable accounts on departure or transfer rather than deleting them immediately, to preserve the audit trail; delete only after the standard retention period.
- Review the access-request log against active staff rosters at each rollout phase (see `access-management/role-permissions-matrix.md`).

## Patching & updates

- Workstations should be on a monthly patch cycle; use `Get-SystemHealthReport.ps1` to flag machines with a pending reboot or stale patch level before a go-live date.
- Confirm KINDL client prerequisites with `Get-SoftwareInventory.ps1` ahead of each office's go-live rather than discovering gaps on cutover day.

## Least privilege

- Default every new account to the minimum access its role requires (see the permissions matrix). Escalate temporary elevated access as a logged, time-boxed exception tied to a specific ticket — never as a standing change.

## Incident & ticket documentation

Every ticket should capture, at minimum:
1. **What was reported** — the user's own description of the issue.
2. **What was found** — diagnostic output (e.g. from `Test-NetworkConnectivity.ps1` or `Get-SystemHealthReport.ps1`).
3. **What was done** — the specific fix or change made.
4. **Follow-up needed**, if any — escalation, parts ordered, a scheduled re-check.

This keeps tickets useful for pattern-spotting across offices (e.g. "three offices in Region 12 hit the same connectivity issue this week") rather than one-off records that get closed and forgotten.

## Incident escalation

- Anything touching driver data access, suspected unauthorized access, or a security-relevant anomaly gets escalated immediately rather than resolved and closed quietly — even if the immediate symptom is fixed.
