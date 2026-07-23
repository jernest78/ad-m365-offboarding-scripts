# Active Directory & Microsoft 365 Offboarding Scripts

Free, production-ready PowerShell scripts for automating **employee offboarding** across **Active Directory**, **Exchange Online**, and **Azure AD (Entra ID)**.

Maintained by the team behind [ADATT](https://adatt.unifosec.com) — an identity lifecycle automation tool for AD & Microsoft 365. These scripts accompany our guide: [PowerShell Scripts for AD Offboarding: Free Templates for IT Admins](https://adatt.unifosec.com/blog/powershell-scripts-ad-offboarding).

## The Scripts

| Script | What it does |
|---|---|
| [`Disable-ADUser.ps1`](scripts/Disable-ADUser.ps1) | Basic offboarding: disable account, reset password, stamp description, log |
| [`Complete-ADOffboarding.ps1`](scripts/Complete-ADOffboarding.ps1) | Full AD offboarding: groups, manager, GAL, Disabled OU, expiration, before/after CSV export |
| [`Bulk-Offboarding.ps1`](scripts/Bulk-Offboarding.ps1) | Bulk terminations from a CSV with per-user success/failure results |
| [`Offboard-ExchangeMailbox.ps1`](scripts/Offboard-ExchangeMailbox.ps1) | Convert mailbox to shared, auto-reply, hide from GAL, grant manager access |
| [`Cleanup-AzureADDevices.ps1`](scripts/Cleanup-AzureADDevices.ps1) | Remove registered devices, revoke refresh tokens, reset MFA ⚠️ *uses deprecated AzureAD/MSOnline modules — see note below* |
| [`Master-Offboarding.ps1`](scripts/Master-Offboarding.ps1) | All-in-one: AD + Exchange Online + Azure AD with full transcript logging |

## Prerequisites

- Active Directory PowerShell module (`Install-WindowsFeature RSAT-AD-PowerShell` on servers, `Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools` on Windows 10/11)
- `ExchangeOnlineManagement` module for the Exchange scripts
- Domain Admin or delegated permissions for user management
- PowerShell 5.1+ (PowerShell 7 recommended)

## Before You Run These

1. **Test on non-production accounts first.** Every environment is different.
2. **Review the parameters** — OU paths, log paths, and auto-reply text are examples; change them for your org.
3. **Use least-privilege service accounts** — don't run these as your daily-driver Domain Admin.
4. **Audit who runs them.** These scripts log actions, but access to the scripts themselves should be controlled.
5. **Protected accounts:** the scripts don't stop you from offboarding a Domain Admin. Double-check the username before pressing Enter.

## ⚠️ AzureAD Module Deprecation

`Cleanup-AzureADDevices.ps1` and the Azure AD section of `Master-Offboarding.ps1` use the **AzureAD** and **MSOnline** modules, which Microsoft has deprecated and retired in favor of [Microsoft Graph PowerShell](https://learn.microsoft.com/en-us/powershell/microsoftgraph/migration-steps). They're included because many environments still run them, but plan your migration to `Connect-MgGraph` equivalents.

This kind of breaking change is the ongoing tax of script-based offboarding — we wrote up the full trade-off analysis here: [ADATT vs PowerShell Scripts](https://adatt.unifosec.com/vs/powershell-scripts).

## When Scripts Aren't Enough

These scripts work well for occasional terminations run by the person who understands them. They don't give you:

- A GUI that non-scripters can safely use
- Approval workflows and role-based access control
- Automatic updates when Microsoft changes APIs
- Recovery from partial failures (account disabled but mailbox still live)
- Multi-tenant management for MSPs
- Compliance-grade audit reporting out of the box

If you're hitting those limits, that's what [ADATT](https://adatt.unifosec.com) is for — no per-user fees, runs on your workstation, [14-day money-back guarantee](https://adatt.unifosec.com/trial).

## Related Guides

- [Complete Active Directory Offboarding Checklist](https://adatt.unifosec.com/blog/active-directory-offboarding-checklist)
- [Automating Exchange Mailbox Conversion](https://adatt.unifosec.com/blog/automate-exchange-mailbox-conversion)
- [Azure AD Device Removal Best Practices](https://adatt.unifosec.com/blog/azure-ad-device-removal-best-practices)
- [Offboarding Mistakes That Cause Security Breaches](https://adatt.unifosec.com/blog/offboarding-mistakes-security-breaches)

## Contributing

Issues and PRs welcome — especially Microsoft Graph rewrites of the Azure AD scripts, additional edge-case handling, and support for hybrid Exchange environments.

## License

[MIT](LICENSE) — use them, modify them, ship them. Attribution appreciated but not required.
