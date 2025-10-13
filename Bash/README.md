# Bash – Shell Automation & CI/CD Utilities

This folder hosts shell scripts for provisioning, CI/CD workflows, and local developer tooling.

## Usage
```bash
chmod +x ./script_name.sh
./script_name.sh --help
```

## Conventions
- Target **POSIX sh** or **bash**; avoid non-portable features when possible.
- Include `set -euo pipefail` for safer execution.
- Use long-form flags and print `--help` usage.

## Template for new scripts
See [`SCRIPT_TEMPLATE.md`](SCRIPT_TEMPLATE.md).
