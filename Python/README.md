# Python – Automation & Tools

This folder hosts Python-based automation and SDK integrations for cloud operations and platform engineering.

## Scripts Index
- **export_azure_users_full_parallel.py** → Export Entra ID (Azure AD) users with security groups, directory roles, and RBAC across all subscriptions. See detailed doc: [`export_azure_users_full_parallel.md`](export_azure_users_full_parallel.md).

> Add new scripts using the template below to keep documentation consistent.

## Setup
```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Conventions
- Each script ships with a **companion README** using the uniform template.
- Prefer `argparse` for CLI flags; include `--help`.
- Log actionable errors; exit non-zero on failure.

## Template for new scripts
See [`SCRIPT_TEMPLATE.md`](SCRIPT_TEMPLATE.md). Copy it next to your script and adjust.
