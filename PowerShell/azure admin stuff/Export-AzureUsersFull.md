# Azure User Export – PowerShell

## 📌 Overview
Exports all Entra ID users with their security groups, directory roles, and RBAC role assignments across all subscriptions the identity can read.

## 🔧 Prerequisites
- Runtime: PowerShell 7+ (`pwsh`)
- Dependencies: Modules: `Az.Accounts`, `Az.Resources`, `Microsoft.Graph`
- Permissions: Microsoft Graph: `User.Read.All`, `Group.Read.All`, `Directory.Read.All` (admin consent)
Azure RBAC: Reader (or permission to read role assignments) on subscriptions

## ⚙️ Parameters & Arguments
- `-OutPath` (string): Output CSV path (default: `users_full.csv`)

## 🚀 Usage Examples
```powershell
Install-Module Az.Accounts,Az.Resources -Scope CurrentUser -Force
Install-Module Microsoft.Graph -Scope CurrentUser -Force
pwsh ./Export-AzureUsersFull.ps1 -OutPath users_full.csv
```
```powershell
# With pre-authenticated sessions
Connect-AzAccount
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","Directory.Read.All"
pwsh ./Export-AzureUsersFull.ps1 -OutPath ./out/users_full.csv
```

## 🗂️ Expected Output
A CSV containing columns:
- `DisplayName`, `UPN`, `Email`
- `SecurityGroups`, `DirectoryRoles`, `RBACRoles`
RBAC entries are formatted as `RoleName @ /subscriptions/<sub>/.../scope`.

## 🧰 Troubleshooting
- Throttling (429): reduce concurrency or add retries.
- Permission denied: verify roles/consents listed above.
- Network/timeout: rerun; ensure outbound access to APIs.

## 🔁 CI/CD & Automation
Schedule with GitHub Actions or Azure Automation. Store credentials securely and upload the resulting CSV as an artifact or to storage.

## 📥 Next Steps
- Extend with filters (e.g., specific groups or subscriptions).
- Export to storage, email reports, or push to a SIEM.
