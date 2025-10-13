
# Security Policy

## Supported Versions
Security updates apply to the latest major release.

| Version | Supported |
|----------|------------|
| 6.x | ✅ |
| <6.0 | ❌ |

## Reporting a Vulnerability
Report security issues privately by opening a confidential issue or contacting the maintainers.

Please include:
- A description of the vulnerability.
- Steps to reproduce (if applicable).
- Potential impact and suggested mitigations.

We aim to acknowledge all reports within **5 business days**.

## Safe Operation
- The toolkit performs **read-only discovery and inventory** actions.
- No destructive operations are executed.
- Always store credentials in **environment variables**, not source files.
- For Azure, vSphere, and AD, use accounts with least-privilege read access.
