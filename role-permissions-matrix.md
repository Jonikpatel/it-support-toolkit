# Role-Based Permissions Matrix

Defines standardized access levels for regional branch personnel during enterprise rollouts. User accounts are provisioned strictly against this matrix (via `scripts/New-UserAccount.ps1`) to ensure consistent security baselines across branch locations and eliminate ad-hoc privilege creep.

---

## Access Matrix

| Role | Enterprise Portal Access | View Records | Edit Records | Admin Console | Assigned Security Groups |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Front Desk Clerk** | Read / Write (own branch transactions) | Yes | Own transactions only | No | `EnterpriseApp-StandardUsers`, `Branch-Printers` |
| **Office Supervisor** | Read / Write (branch-wide) | Yes | Branch-wide | No | `EnterpriseApp-StandardUsers`, `Branch-Printers`, `EnterpriseApp-BranchSupervisors` |
| **IT Support** | Tools / diagnostics only | No | No | Helpdesk utilities only | `EnterpriseApp-StandardUsers`, `IT-Tier2-Diagnostics`, `HelpdeskTools` |
| **Regional Admin** | Full Read / Write (region-wide) | Yes | Region-wide | Yes | `EnterpriseApp-StandardUsers`, `EnterpriseApp-BranchSupervisors`, `EnterpriseApp-RegionalAdmins` |

---

## Core Security Principles

* **Least Privilege by Default:** IT Support accounts do not have access to customer, client, or transactional record data. If a specific troubleshooting ticket requires elevated or temporary record access, it must be formally requested, approved, and logged as a time-limited exception.
* **No Standing Admin Privileges:** Access to the enterprise admin console is strictly restricted to the Regional Admin role. Broader domain administrative tasks require standard privileged access management (PAM) procedures.
* **Role-Bound Permissions:** Access follows the job function, not the individual. When staff members transfer branches or change operational roles, their account is deprovisioned and re-provisioned against the target role rather than layering new groups over legacy permissions.

---

## Audit & Review Cadence

To maintain compliance and audit readiness:
1. **Pre-Go-Live:** Validate branch roster against requested AD accounts.
2. **Day 30 Post-Cutover:** Reconcile active accounts against branch rosters and `access-request-log.csv`.
3. **Quarterly Review:** Audit all active accounts and security group memberships to prune stale access and verify transfer records.
