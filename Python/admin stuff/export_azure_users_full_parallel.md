# Azure User Export (Parallel) – Python

## 📌 Overview
Exports all Entra ID (Azure AD) users with security groups, directory roles, and RBAC role assignments across all accessible subscriptions. Parallelized for speed.

## 🔧 Prerequisites
- Runtime: Python 3.10+
- Dependencies: `azure-identity`, `azure-mgmt-authorization`, `azure-mgmt-resource`, `requests`
- Permissions: Microsoft Graph: `User.Read.All`, `Group.Read.All`, `Directory.Read.All` (admin consent)
Azure RBAC: Reader (or permission to read role assignments) on subscriptions

## ⚙️ Parameters & Arguments
- `--out` / `-o` (string): Output CSV path (default: `azure_users_full.csv`)
- `--workers` / `-w` (int): Parallel workers (default: 8)

## 🚀 Usage Examples
```bash
export AZURE_TENANT_ID="<tenant-id>"
export AZURE_CLIENT_ID="<client-id>"
export AZURE_CLIENT_SECRET="<client-secret>"
pip install azure-identity azure-mgmt-authorization azure-mgmt-resource requests
python export_azure_users_full_parallel.py --out users_full.csv --workers 8
```
```bash
# Using Azure CLI auth instead of a service principal
az login
python export_azure_users_full_parallel.py -o users_full.csv -w 12
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
Use `.github/workflows/export-azure-users.yml` to run on a schedule. The job sets SP credentials from repo secrets, executes the exporter, and uploads `users_full.csv` as an artifact.

## 📥 Next Steps
- Extend with filters (e.g., specific groups or subscriptions).
- Export to storage, email reports, or push to a SIEM.
