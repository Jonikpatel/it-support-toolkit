# KINDL Regional IT Support Toolkit

A practical toolkit simulating the IT support and Active Directory administration needed during a statewide enterprise rollout (modeled after KYTC's KINDL transition across regional driver licensing offices).

---

## Overview

Deploying enterprise systems across distributed field offices comes down to day-one operational readiness: staff accounts must work immediately, workstations need reliable network paths, and local branch hardware must be vetted before go-live. When issues arise during cutover, field techs need fast triage tools and clean audit trails.

This repository compiles the core PowerShell automations, access management matrices, and support documentation a regional field support specialist uses to keep office rollouts on schedule.

---

## Repository Structure

| Directory | Purpose |
| :--- | :--- |
| `scripts/` | PowerShell automations for user lifecycle management (provisioning/deprovisioning), endpoint health checks, network path validation, and hardware/software inventory. |
| `access-management/` | Role-Based Access Control (RBAC) matrix and standardized ticket request templates to enforce least-privilege access and audit readiness. |
| `docs/` | SOPs covering workstation patching cycles, credential hygiene, post-cutover incident management, and escalation runbooks. |

---

## Scenario This Models

A new enterprise platform (KINDL) rolls out region by region to local licensing branches. Each go-live cycle follows a structured operational path:

1. **Pre-Deployment Readiness:** Audit local subnet routes, verify domain reachability, and inventory field office hardware prior to migration windows.
2. **Day-One Account Provisioning:** Generate domain accounts with proper OU placement, assigned security groups, and mailbox access mapped directly to staff roles.
3. **Cutover Support:** Rapidly troubleshoot peripheral handshakes (card readers, camera feeds, document scanners) and network drops under load.
4. **Lifecycle & Access Control:** Maintain an auditable log of permission grants, role transfers between offices, and prompt offboarding.

---

## Environment & Configuration

* **Runtime:** PowerShell 5.1+ / PowerShell 7.x
* **Dependencies:** `ActiveDirectory` RSAT module
* **Target OS:** Windows 10/11 Enterprise & Windows Server 2019/2022
* **Usage:** Scripts contain parameterized variables for domain controllers, OU paths, and log destinations. Update the config blocks at the top of each script to match your local Active Directory forest structure before running.

---

## Author

**Jonik Patel**  
Dual MBA / MS in Information Systems | Former KYTC Data Systems Intern  
Focused on enterprise systems administration, IT infrastructure support, and operational workflows across Kentucky state government agencies.
