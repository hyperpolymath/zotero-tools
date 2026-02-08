# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

### Preferred Contact Method

Report security vulnerabilities to: **security@[REPOSITORY-OWNER-EMAIL]**

### What to Include

Please include the following information:

- **Type of vulnerability** (e.g., XSS, SQL injection, improper input validation)
- **Full paths of affected source files**
- **Location of affected source code** (tag/branch/commit or direct URL)
- **Step-by-step instructions to reproduce** the issue
- **Proof-of-concept or exploit code** (if possible)
- **Impact of the vulnerability** (what an attacker could achieve)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity
  - Critical: 7 days
  - High: 14 days
  - Medium: 30 days
  - Low: 90 days

### Disclosure Policy

- We follow **coordinated disclosure**
- We will notify you when the vulnerability is fixed
- We request **90 days** before public disclosure
- We will credit you in CHANGELOG.md (if desired)

## Security Measures

### Type Safety

- **TypeScript strict mode**: Compile-time type checking
- **Zod runtime validation**: Runtime type safety for external data
- **No `any` types**: Full type coverage

### Input Validation

- **Citation data validation**: All citation fields validated with Zod schemas
- **URL sanitization**: URLs checked for validity before processing
- **DOI/ISBN format validation**: Pattern matching for identifiers

### Memory Safety

- **No unsafe operations**: No direct memory access
- **No eval()**: No dynamic code evaluation
- **No innerHTML**: DOM manipulation via safe APIs only

### Privacy

- **No tracking**: Zero telemetry or analytics
- **Local-first**: All processing happens locally
- **No API keys stored**: No credentials in plugin
- **No external requests**: Offline-first architecture

### Dependencies

- **Minimal dependencies**: Only Zod for runtime validation
- **Regular updates**: Automated dependency security scanning
- **No unmaintained packages**: Only actively maintained dependencies

## Security Considerations

### Zotero Plugin Security

NSAI operates within Zotero's security sandbox:

- **Limited permissions**: Only storage and tabs
- **No network access**: Cannot make external requests
- **No file system access**: Cannot read/write arbitrary files
- **WebExtension API**: Modern, restricted plugin architecture

### Data Handling

- **User data stays local**: Validation results never leave the user's machine
- **No cloud storage**: No data sent to external servers
- **Export is explicit**: User must manually export to Fogbinder

### Fogbinder Handoff

When exporting to Fogbinder:

- **User-initiated only**: Export requires explicit user action
- **JSON format**: Plain text, inspectable data
- **No embedded code**: Only data, no executable content
- **Sanitized output**: All data validated before export

## Known Security Limitations

### Not Validated

NSAI performs **structural validation** only:

- ✅ Checks if DOI format is valid
- ❌ Does NOT verify DOI actually points to the cited work
- ✅ Checks if URL is well-formed
- ❌ Does NOT fetch URL content or verify it's accessible

### Trust Boundary

NSAI trusts Zotero's data:

- Citations from Zotero library are assumed to be user-provided
- No protection against malicious data in Zotero database
- Zotero's security model is the first line of defense

## Security Best Practices for Users

1. **Keep Zotero updated**: Use latest stable version
2. **Review exported data**: Inspect JSON before importing to Fogbinder
3. **Use HTTPS for Zotero sync**: If using Zotero cloud sync
4. **Backup your library**: Regular backups of Zotero data

## Security Audit History

| Date | Auditor | Findings | Status |
|------|---------|----------|--------|
| 2024-11-22 | Self-audit | Initial security review | Complete |

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Zotero Security Policy](https://www.zotero.org/support/security)
- [WebExtension Security](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Security_best_practices)
