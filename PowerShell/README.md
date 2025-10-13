# PowerShell – Admin & Cloud Automation

This folder contains PowerShell scripts for Azure, Windows, and Microsoft 365 automation.

## Running Scripts
- Use **PowerShell 7+** (`pwsh`) when possible for cross-platform support.
- Install required modules in **CurrentUser** scope.
- Prefer **Az** and **Microsoft.Graph** modules for cloud automation.

## Scripts Index
- **Export-AzureUsersFull.ps1** → Export Entra ID users, security groups, directory roles, and RBAC across all subscriptions. See detailed doc: [`Export-AzureUsersFull.md`](Export-AzureUsersFull.md).

## Modules
```powershell
Install-Module Az.Accounts,Az.Resources -Scope CurrentUser -Force
Install-Module Microsoft.Graph -Scope CurrentUser -Force
```

## Template for new scripts
See [`SCRIPT_TEMPLATE.md`](SCRIPT_TEMPLATE.md). Use it to document parameters, examples, and troubleshooting.
