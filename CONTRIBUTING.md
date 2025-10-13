# Contributing Guide

Thanks for your interest in contributing! This repository aims to provide high-quality, reusable automation and IaC building blocks.

## Ground Rules
- Keep changes **small and focused**.
- Write **clear commit messages** (Conventional Commits preferred).
- Ensure **docs are updated** (folder or per-file README where applicable).
- CI must pass: formatting, validation, and basic checks.

## Workflow
1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feat/<short-description>
   ```
2. **Develop** your change with tests/examples where useful.
3. **Lint/Format**:
   - Terraform: `terraform fmt -recursive` (and `terraform validate`)
   - Python: `ruff .` or `flake8` (if configured), and `black` if used
   - PowerShell: `pwsh -File ./.scripts/ps-lint.ps1` (if present)
4. **Commit** with clear messages:
   - `feat(terraform): add aws vpc baseline module`
   - `fix(python): handle throttling in export script`
5. **Open a Pull Request** to `main`:
   - Link issues
   - Include screenshots/snippets for notable outputs
6. **Reviews & Approvals**:
   - Maintainers will review; requested changes may follow

## CI/CD Expectations
- PRs trigger plan/validate for Terraform and run script checks where configured.
- Protected environments gate applies (if enabled).

## Documentation
- Add or update `README.md` in the relevant folder.
- For new scripts, copy `SCRIPT_TEMPLATE.md` and tailor it.
