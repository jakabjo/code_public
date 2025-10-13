
## 1. Overview

The CMDB Python Toolkit inventories infrastructure across hybrid environments (on‑prem, Azure, vSphere, and unmanaged subnets). It discovers assets, collects system details over WinRM/SSH, enriches with DNS and AD metadata, normalizes tags, and exports reports (JSON/CSV/HTML/SQLite; optional ServiceNow).

Pipeline:

```
╔═══════════════════════════════════════════════════════════════════════╗
║                          CMDB INVENTORY PIPELINE                      ║
╠═══════════════════════════════════════════════════════════════════════╣
║  DISCOVERY  →  COLLECTION  →  ENRICHMENT  →  EXPORT / REPORTING       ║
╚═══════════════════════════════════════════════════════════════════════╝
```

Supported sources and protocols:

| Source               | How we discover                 | Collection |
|----------------------|---------------------------------|------------|
| Active Directory     | LDAP/LDAPS queries              | WinRM/SSH  |
| Azure                | Resource Graph / ARM APIs       | WinRM/SSH  |
| vSphere              | pyVmomi                         | WinRM/SSH  |
| Subnets (unmanaged)  | ICMP ping (optional TCP probe)  | n/a        |

Design goals: safe read‑only operation, modular providers/collectors, clear toggles, predictable outputs, and fast parallel runs.

---

## 2. Quick Start

### 2.1 Prerequisites

- Python **3.10+**
- Network reachability to AD, Azure, vSphere, and targets (WinRM/SSH)
- Credentials with **read‑only** access
- Optional: WSL on Windows for Linux‑style tooling

### 2.2 Install

```bash
python -m venv .venv
source .venv/bin/activate            # Windows PowerShell: .venv\Scripts\Activate.ps1
pip install -U pip
pip install -r requirements.txt
```

### 2.3 Minimal config

Create `config.yaml`:

```yaml
discovery:
  active_directory:
    enabled: true
    server: "ldaps://ad.example.local"
    base_dn: "DC=example,DC=local"

  azure:
    enabled: true
    subscriptions: ["11111111-1111-1111-1111-111111111111"]

  vsphere:
    enabled: true
    server: "vcenter.example.local"

  subnet_scan:
    enabled: true
    targets: ["10.0.0.0/24"]
    ping_only: true

collect:
  windows: { enabled: true }
  linux:   { enabled: true }
  software:{ enabled: false }

features:
  discovery:  { ad: true, azure: true, vsphere: true, subnet_scan: true }
  enrichment: { dns: true, ad_ou: true, transforms: true }
  collection: { windows: true, linux: true }

fields:
  include: ["host","provider","OS","Version","IPs","environment","ad_ou","resolved_name"]
  exclude: []

export:
  json: true
  csv: true
  html: true
  sqlite:
    enabled: true
    file: "out/inventory.db"
```

### 2.4 Environment variables

Set only what you need (examples shown as placeholders):

```bash
export AD_BIND_USER="svc_cmdb@example.local"
export AD_BIND_PASSWORD="********"
export AZURE_TENANT_ID="azure-tenant-id"
export AZURE_CLIENT_ID="azure-app-id"
export AZURE_CLIENT_SECRET="********"
export VSPHERE_USER="vsphere-readonly@example.local"
export VSPHERE_PASSWORD="********"
export WINRM_USER="domain\readonly"
export WINRM_PASSWORD="********"
export SSH_USER="readonly"
export SSH_PASSWORD="********"     # or set up keys
```

Windows PowerShell equivalents use `$env:VAR="value"`.

### 2.5 Run

```bash
python cmdb_inventory.py -c config.yaml -o out --autotune --tui
```

Typical outputs (created under `out/`):

```
out/
├─ inventory.json
├─ inventory.csv
├─ inventory.html
└─ inventory.db
```

---

## 3. CLI Usage

```
usage: cmdb_inventory.py [-c CONFIG] [-o OUTDIR] [--fast] [--dry-run]
                         [--autotune] [--workers N]
                         [--include-fields CSV] [--exclude-fields CSV]
                         [--tui]
```

Key flags:

- `-c, --config` Path to `config.yaml` (default: `config.yaml`)
- `-o, --out` Output directory (default: `out`)
- `--fast` Skips heavy tasks: software inventory, DNS reverse lookups, TCP probe
- `--dry-run` Discovery only; no WinRM/SSH collection
- `--autotune` Smart worker count from CPU and target size
- `--workers N` Manual concurrency override
- `--include-fields` Comma list of fields to keep in final dataset
- `--exclude-fields` Comma list of fields to drop
- `--tui` Terminal progress viewer with ETA

Examples:

```bash
# Fast recon with progress, autotuned workers
python cmdb_inventory.py -c config.yaml -o out --fast --autotune --tui

# Run with only specific fields
python cmdb_inventory.py -c config.yaml -o out --include-fields host,OS,IPs,provider

# Exclude heavy fields
python cmdb_inventory.py -c config.yaml -o out --exclude-fields Software,open_ports

# Discovery-only to validate targets
python cmdb_inventory.py -c config.yaml -o out --dry-run
```

---

## 4. Configuration Reference

High‑level schema (representative subset):

```yaml
discovery:
  active_directory:
    enabled: true
    server: "ldaps://ad.example.local"
    base_dn: "DC=example,DC=local"
    enrich_non_ad: true      # If true, attempt OU lookup for known hosts

  azure:
    enabled: true
    subscriptions: ["<sub-id-1>", "<sub-id-2>"]

  vsphere:
    enabled: true
    server: "vcenter.example.local"

  subnet_scan:
    enabled: true
    targets: ["10.0.0.0/24", "192.168.1.0/24"]
    ping_only: true          # Set false to allow light TCP probe

collect:
  windows: { enabled: true }
  linux:   { enabled: true }
  software:
    enabled: false           # Set true to inventory installed packages/apps

features:
  discovery:  { ad: true, azure: true, vsphere: true, subnet_scan: true }
  enrichment: { dns: true, ad_ou: true, transforms: true }
  collection: { windows: true, linux: true }

fields:
  include: []                # Keep only these fields (wins over exclude)
  exclude: []                # Drop these fields

export:
  json: true
  csv: true
  html: true
  sqlite:
    enabled: true
    file: "out/inventory.db"
  servicenow:
    enabled: false
    instance: "https://example.service-now.com"
    table: "cmdb_ci_computer"
    user_env: "SN_USER"
    pass_env: "SN_PASS"
```

Notes:

- `features.*` toggles turn *capabilities* on/off (discovery, enrichment, collection).
- `fields.include/exclude` shape the **final** dataset.
- `subnet_scan.ping_only: true` is the safest mode; TCP probe is optional and throttled.

---

## 5. Output Formats

### 5.1 JSON

Example row:

```json
{
  "host": "example-host-1",
  "provider": "azure",
  "OS": "Windows Server 2022",
  "Version": "10.0.20348",
  "IPs": ["10.0.0.10", "52.160.10.10"],
  "ad_ou": "OU=Servers,DC=example,DC=local",
  "environment": "production",
  "resolved_name": "example-host-1.example.local"
}
```

### 5.2 CSV

Columns follow the normalized schema (post‑filters). Open in Excel or BI tools.

### 5.3 HTML

Lightweight report for quick review. Open `out/inventory.html` after a run.

### 5.4 SQLite

Embedded database at `out/inventory.db` with a single `inventory` table (or provider‑specific tables if enabled).

---

## 6. Performance & Scaling

Concurrency:

- `--autotune` chooses a thread pool based on CPU and target count.
- Manual override via `--workers N`.

Estimated runtimes (indicative; network‑bound):

| Scale  | Hosts | Fast mode | Full mode (w/ DNS) |
|--------|-------|-----------|---------------------|
| Small  | 50    | 2–3 min   | 4–6 min             |
| Medium | 500   | 15–25 min | 30–45 min           |
| Large  | 5000  | 45–90 min | 90–150 min          |

To reduce runtime:
- Use `--fast`, or disable `collect.software` and `features.enrichment.dns`.
- Scope discovery (subset of subscriptions, OUs, clusters, or subnets).
- Run from a vantage point close to targets (self‑hosted runner).

---

## 7. GitHub Actions Automation

Create `.github/workflows/cmdb-inventory.yml` to run on schedule and on demand. Minimal, linter‑friendly pattern (secrets read inside the script body):

```yaml
name: CMDB Inventory

on:
  schedule:
    - cron: "30 2 * * *"   # 02:30 UTC daily
  workflow_dispatch:
    inputs:
      mode:
        description: "Run mode"
        required: true
        default: "full"
        type: choice
        options: ["full", "dry-run", "fast"]

env:
  CONFIG_FILE: config.yaml
  OUT_DIR: out

jobs:
  inventory:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - shell: bash
        run: |
          set -euo pipefail
          python -m pip install --upgrade pip
          pip install -r requirements.txt

          # Prefer config from secret if present, else repo file(s)
          if [ -n "${{ secrets.CMDB_CONFIG_YAML }}" ]; then
            printf '%s
' "${{ secrets.CMDB_CONFIG_YAML }}" > "${CONFIG_FILE}"
          elif [ -f config.yaml ]; then
            cp config.yaml "${CONFIG_FILE}"
          elif [ -f config.example.yaml ]; then
            cp config.example.yaml "${CONFIG_FILE}"
          else
            echo "No config found" >&2; exit 1
          fi

          # Export secrets for the run (masked in logs)
          export AD_BIND_USER="${{ secrets.AD_BIND_USER }}"
          export AD_BIND_PASSWORD="${{ secrets.AD_BIND_PASSWORD }}"
          export AZURE_TENANT_ID="${{ secrets.AZURE_TENANT_ID }}"
          export AZURE_CLIENT_ID="${{ secrets.AZURE_CLIENT_ID }}"
          export AZURE_CLIENT_SECRET="${{ secrets.AZURE_CLIENT_SECRET }}"
          export VSPHERE_USER="${{ secrets.VSPHERE_USER }}"
          export VSPHERE_PASSWORD="${{ secrets.VSPHERE_PASSWORD }}"
          export WINRM_USER="${{ secrets.WINRM_USER }}"
          export WINRM_PASSWORD="${{ secrets.WINRM_PASSWORD }}"
          export SSH_USER="${{ secrets.SSH_USER }}"
          export SSH_PASSWORD="${{ secrets.SSH_PASSWORD }}"

          MODE="${{ github.event.inputs.mode || 'full' }}"
          ARGS="-c ${CONFIG_FILE} -o ${OUT_DIR} --autotune"
          [ "${MODE}" = "dry-run" ] && ARGS="${ARGS} --dry-run"
          [ "${MODE}" = "fast" ] && ARGS="${ARGS} --fast"

          python cmdb_inventory.py ${ARGS}
          ls -l "${OUT_DIR}" || true

      - uses: actions/upload-artifact@v4
        with:
          name: cmdb-inventory-${{ github.run_id }}
          path: |
            ${{ env.OUT_DIR }}/inventory.json
            ${{ env.OUT_DIR }}/inventory.csv
            ${{ env.OUT_DIR }}/inventory.html
            ${{ env.OUT_DIR }}/inventory.db
          retention-days: 14
```

Add repository secrets: `AD_BIND_USER`, `AD_BIND_PASSWORD`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `VSPHERE_USER`, `VSPHERE_PASSWORD`, `WINRM_USER`, `WINRM_PASSWORD`, `SSH_USER`, `SSH_PASSWORD`, and optionally `CMDB_CONFIG_YAML`.

---

## 8. VS Code Integration (WSL friendly)

- Install extensions: Python, Pylance, Remote‑WSL, YAML, GitHub Actions, Ruff/Flake8.
- Open your repo via **Remote‑WSL**.  
- Select interpreter: `.venv/bin/python`.
- Optional `.vscode/launch.json` target:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "CMDB: Run (autotune)",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/cmdb_inventory.py",
      "args": ["-c", "config.yaml", "-o", "out", "--autotune", "--tui"],
      "console": "integratedTerminal"
    }
  ]
}
```

---

## 9. Security & Safe Operation

- The toolkit executes **read‑only** operations (no configuration changes).  
- Use least‑privilege accounts.  
- Avoid embedding secrets in files; prefer environment variables or GitHub Actions secrets.  
- Subnet scanning defaults to **ping‑only**; TCP probing is optional and limited.  
- Logs avoid sensitive fields and are stored locally under the output directory.

---

## 10. Troubleshooting

| Symptom                         | Likely cause                          | Fix |
|---------------------------------|---------------------------------------|-----|
| WinRM timeout                   | Firewall or auth                      | Validate TCP 5985/5986, creds, SPNs |
| SSH auth failure                | Keys/permissions                      | Verify key perms; try password once |
| Empty AD results                | Base DN or filter too narrow          | Adjust `base_dn`, verify bind user  |
| Slow DNS                        | Resolver timeouts                     | Disable `enrichment.dns` or set DNS |
| APT/dpkg errors in WSL          | Corrupt caches or I/O on VHDX         | `dpkg --configure -a`, `apt clean`, move distro off OneDrive |

Enable debug logging if available (`--debug`) and try `--dry-run` to isolate discovery from collection.

---

## 11. Roadmap

- `--profile minimal|balanced|deep` presets  
- Async DNS + caching  
- Advanced HTML dashboards and charts  
- Postgres/MSSQL exporters  
- Plugin SDK for custom discovery/enrichment/export
- Adding AWS

---

## 12. License and Contributions

This repository typically ships under the MIT license (`LICENSE`). Contributions are welcome; see `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`. Security issues should follow `SECURITY.md` guidance.

---

## 13. Example End‑to‑End Session

```bash
# 1) Create and edit config.yaml (see above)
# 2) Set environment variables (at minimum, one provider)
# 3) Run
python cmdb_inventory.py -c config.yaml -o out --autotune --tui

# 4) Review outputs
python inventory_viewer.py out/inventory.json --columns host,provider,OS,IPs --page-size 30 --width 140
xdg-open out/inventory.html || open out/inventory.html || start out\inventory.html
```

End of README.
