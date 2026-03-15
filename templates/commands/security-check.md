---
description: Scan the codebase for common security vulnerabilities
allowed-tools: Bash, Read, Glob, Grep
---

Perform a security review of the codebase or a specific file/directory.
Arguments: $ARGUMENTS (optional path to scan; defaults to current directory)

## Scope

Target: $ARGUMENTS (or `.` if not specified)

## Checks to Perform

### Secrets and Credentials
- Hardcoded API keys, tokens, passwords, or private keys in source files
- Secret values committed to git history: `git log -p | grep -i 'api_key\|password\|secret\|token'`
- `.env` files or credential files that should be in `.gitignore`

### Injection Vulnerabilities
- SQL injection: string-concatenated queries instead of parameterized statements
- Command injection: unsanitized user input passed to `exec`, `eval`, `shell`, `subprocess`
- XSS: unescaped user input rendered in HTML templates

### Authentication and Authorization
- Missing authentication checks on sensitive endpoints
- Broken access control (user A can access user B's resources)
- Insecure session handling or token storage

### Dependency Vulnerabilities
- Run `npm audit` / `pip-audit` / `cargo audit` / `bundler-audit` if available
- Check for packages with known CVEs

### Cryptography
- Use of weak algorithms: MD5, SHA1 for passwords, ECB mode, DES
- Hardcoded cryptographic keys or IVs
- Insecure random number generation for security-sensitive values

### File and Path Handling
- Path traversal: `../` in user-controlled file paths
- Unrestricted file uploads without type validation

## Output Format

```
## Security Review: [target]

### Critical (fix before deploy)
- [finding] — [file:line] — [explanation and remediation]

### High
- [finding] — [file:line] — [explanation]

### Medium
- [finding] — [file:line]

### Informational
- [finding] — [file:line]

### Clean (no issues found)
- [area checked] ✓
```
