# Role-Based Permissions Matrix

Defines the access level each role gets across regional offices during the KINDL rollout. New accounts are provisioned against this matrix (see `scripts/New-UserAccount.ps1`) so access is consistent from office to office instead of being decided case by case.

| Role | KINDL Access | Can View Records | Can Edit Records | Admin Console | Group Memberships |
|---|---|---|---|---|---|
| Front Desk Clerk | Read/Write (own transactions only) | Yes | Own transactions only | No | `KINDL-Users`, `OfficePrinters` |
| Office Supervisor | Read/Write (office-wide) | Yes | Office-wide | No | `KINDL-Users`, `OfficePrinters`, `KINDL-Supervisors` |
| IT Support | No record access by default | No | No | Helpdesk tools only | `KINDL-Users`, `KINDL-ITSupport`, `HelpdeskTools` |
| Regional Admin | Read/Write (region-wide) | Yes | Region-wide | Yes | `KINDL-Users`, `KINDL-Supervisors`, `KINDL-RegionalAdmins` |

## Principles

- **Least privilege by default.** IT Support accounts do not get record-level access to driver data unless a specific ticket requires it — access is requested and logged separately, not granted by default.
- **No standing admin access.** Admin console access is limited to the Regional Admin role; broader admin needs are handled as time-boxed, logged exceptions.
- **Access follows the role, not the person.** If someone changes roles or offices, their account is deprovisioned and re-provisioned against the new role's group set rather than having permissions manually added on top of the old ones.

## Review cadence

Access should be reviewed at each phase of the rollout (pre-go-live, 30 days post-go-live, and quarterly afterward) against the `access-request-log.csv` to confirm every active account still matches an active role.
