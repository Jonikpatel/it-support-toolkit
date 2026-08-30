# Security & Documentation Practices

Operational guidelines for keeping regional field systems secure and ensuring every support interaction remains auditable throughout the KINDL rollout.

---

## Identity & Access Management

* **Script-Driven Lifecycle:** Provision and deprovision accounts exclusively through `scripts/New-UserAccount.ps1` and `scripts/Remove-UserAccount.ps1`. This ensures automatic audit logging to `access-request-log.csv` and eliminates undocumented, manual group edits.
* **Account Deactivation Over Deletion:** When staff transfer or depart, disable accounts and strip secondary groups rather than deleting the Active Directory object immediately. This preserves security identifiers (SIDs) and maintains historical ticket/file ownership trails until standard data retention periods expire.
* **Roster Reconciliation:** Cross-check the access log against active branch rosters at each rollout phase and quarterly afterward to catch privilege drift early.

---

## Workstation Hygiene & Readiness

* **Monthly Patch Cadence:** Field workstations must maintain current security baselines. Run `scripts/Get-SystemHealthReport.ps1` ahead of go-live dates to catch missing patches or pending reboots before cutover morning.
* **Baseline Application Audits:** Run `scripts/Get-SoftwareInventory.ps1` during pre-deployment site visits to verify core KINDL dependencies (client runtimes, drivers, certified browser versions) instead of discovering software conflicts on launch day.

---

## Least Privilege Enforcement

* **Default Deny / Role Scoping:** New accounts are restricted to the minimum security groups required for daily branch tasks. IT support accounts never have direct access to driver or citizen records.
* **Time-Boxed Escalations:** Any elevated or out-of-band permission grant must be tied to an active ticket, approved by a supervisor, and logged with a clear expiration window—never left as a permanent entitlement.

---

## Incident & Ticket Standards

To spot recurring regional patterns (e.g., recurring subnet drops across a specific district), every support ticket must document:

1. **Reported Issue:** The user's direct description of the failure.
2. **Diagnostic Evidence:** Concrete output from triage tools (e.g., `Test-NetworkConnectivity.ps1` or `Get-SystemHealthReport.ps1`).
3. **Remediation Taken:** Exact steps, registry tweaks, driver reinstalls, or account changes applied.
4. **Follow-Up / Escalation:** Pending hardware replacements, cable drops, or vendor escalations.

---

## Escalation Triggers

Immediately escalate any incident involving:
* Unexplained permission changes or unauthorized access attempts.
* Anomalies involving citizen or driver record queries.
* Repeated authentication failures indicating compromised credentials.

> **Rule:** Never quietly resolve a security-relevant anomaly, even if the immediate technical symptom is fixed. Escalate through the regional security lead and document the timeline.
