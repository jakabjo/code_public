
# Contributing Guidelines

We welcome contributions that improve code quality, expand functionality, and enhance documentation.

## Branching Model
- **main** — production-ready branch.
- **develop** — integration branch for new features.
- **feature/** — prefix for individual enhancements (e.g., `feature/dns-caching`).
- **hotfix/** — prefix for urgent corrections to main.

## Commit Messages
Use clear, conventional messages:
```
feat: add ServiceNow export module
fix: correct WinRM timeout handling
docs: update README with new config fields
```
Prefix types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`.

## Pull Requests
Before submitting a PR:
1. Ensure all code passes linting and local tests.
2. Include an entry in `CHANGELOG.md` under the **Unreleased** section.
3. Reference related issues with `Closes #<issue>` if applicable.
4. Request review from a maintainer.

## Testing
Run local tests using `pytest` or your preferred CI workflow. Always validate YAML schema integrity.

## Maintainers
- **Project Maintainer:** Oversees core merges and release tagging.
- **Core Contributors:** Regular committers with review privileges.

Thank you for supporting transparent, maintainable engineering practices.
