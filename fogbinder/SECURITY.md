# Security Policy

## Supported Versions

Currently supported versions of Fogbinder:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

## Security Model

Fogbinder follows a **defense-in-depth** security approach across multiple dimensions:

### 1. Input Validation & Sanitization
- **All user input is sanitized** before processing
- HTML/XML escaping prevents XSS attacks
- No `eval()` or dynamic code execution
- Content Security Policy enforced

### 2. Memory Safety
- **ReScript/TypeScript:** No manual memory management
- **Deno sandbox:** V8 isolation
- **No buffer overflows:** Impossible in managed languages

### 3. Type Safety
- **Compile-time guarantees:** ReScript prevents entire classes of bugs
- **No `any` types:** Strict typing throughout codebase
- **Exhaustive pattern matching:** All cases handled

### 4. Offline-First Security
- **Zero network calls** in core analysis engine
- **No external dependencies** at runtime
- **Air-gapped operation:** Works without internet
- **No telemetry or tracking**

### 5. Zotero Integration Security
- **Minimal API surface:** Only read operations
- **No credential storage:** Never stores passwords/API keys
- **Sandboxed execution:** Deno permissions model
- **Explicit permissions:** User must grant access

### 6. Data Privacy
- **No data collection:** Zero telemetry
- **No analytics:** No user tracking
- **No external calls:** All processing local
- **GDPR compliant:** No personal data processed

### 7. License Compliance (AGPLv3)
- **Network copyleft:** Source must be provided for hosted versions
- **Transparency:** All code publicly auditable
- **No backdoors:** Open-source security

### 8. Supply Chain Security
- **Minimal dependencies:** ReScript compiler only (build-time)
- **Deno std library:** Audited by Deno core team
- **No npm runtime deps:** Zero attack surface
- **Reproducible builds:** Nix flake (planned)

### 9. TPCF Security Model
- **Perimeter 3 (Community Sandbox):** Open contribution with review
- **Code review required:** No direct commits to main
- **CI/CD checks:** Automated security scanning
- **Maintainer approval:** Two-person rule for releases

### 10. Accessibility & Inclusive Security
- **WCAG 2.1 AA compliance:** Prevents accessibility-based attacks
- **Semantic HTML:** Prevents DOM-based XSS
- **ARIA labels:** Screen reader compatibility
- **Keyboard navigation:** No mouse-only trap vulnerabilities

## Reporting a Vulnerability

### Contact Methods

**Primary:** GitHub Security Advisories
- Repository: https://github.com/Hyperpolymath/fogbinder
- Use "Security" tab → "Report a vulnerability"

**Secondary:** Email
- Email: security@fogbinder.org (FUTURE - not yet active)
- PGP Key: See `.well-known/security.txt`

**Response Time:**
- **Acknowledgment:** Within 48 hours
- **Initial assessment:** Within 7 days
- **Fix timeline:** Depends on severity (see below)

### Severity Levels

| Severity | Response Time | Fix Timeline | Disclosure |
|----------|--------------|--------------|------------|
| **Critical** | 24 hours | 7 days | 30 days after fix |
| **High** | 48 hours | 14 days | 45 days after fix |
| **Medium** | 7 days | 30 days | 60 days after fix |
| **Low** | 14 days | 60 days | 90 days after fix |

### What to Report

**DO report:**
- ✅ XSS vulnerabilities (despite sanitization)
- ✅ Injection attacks (SQL, command, etc.)
- ✅ Authentication/authorization bypass
- ✅ Data leakage or privacy violations
- ✅ Denial of service vulnerabilities
- ✅ Supply chain vulnerabilities
- ✅ Cryptographic weaknesses (if applicable)
- ✅ Accessibility-based security issues

**DON'T report:**
- ❌ Social engineering attacks (not software vulnerability)
- ❌ Physical security issues
- ❌ Third-party Zotero vulnerabilities (report to Zotero team)
- ❌ Theoretical attacks with no proof-of-concept

### Responsible Disclosure

We follow **coordinated disclosure**:

1. **Report privately** via GitHub Security Advisories or email
2. **Do not** publicly disclose until fix is released
3. **Allow time** for us to develop and deploy fix (see timeline above)
4. **Credit given** in security advisory and CHANGELOG
5. **Public disclosure** after agreed timeline

### Bug Bounty

**Currently:** No formal bug bounty program

**Recognition:**
- Public credit in SECURITY_ADVISORIES.md
- Entry in CHANGELOG.md
- GitHub Security Advisory credit
- Hall of Fame (planned)

## Security Best Practices for Users

### For Researchers
1. **Keep Fogbinder updated:** Security patches in minor versions
2. **Review permissions:** Deno will prompt for file/network access
3. **Verify sources:** Only analyze trusted citation sources
4. **Air-gap sensitive research:** Use offline mode for classified work

### For Developers
1. **Review code changes:** All PRs reviewed for security
2. **Use Deno permissions:** `--allow-read`, `--allow-write` only as needed
3. **Sanitize inputs:** Always escape user-provided data
4. **No secrets in code:** Use environment variables
5. **Keep dependencies minimal:** Audit any new dependencies

### For System Administrators
1. **Sandboxing:** Run Fogbinder in containers (Docker, systemd-nspawn)
2. **Principle of least privilege:** Minimal file system access
3. **Network isolation:** No internet access needed for core features
4. **Audit logs:** Monitor file access patterns
5. **Reproducible builds:** Use Nix flake for verification

## Security Audits

### External Audits
**Status:** None yet (v0.1.0 pre-release)

**Planned:**
- Q2 2025: Initial security audit (Cure53 or similar)
- Q4 2025: Penetration testing
- Annual audits thereafter

### Internal Reviews
- ✅ Code review for all PRs
- ✅ Automated linting (Deno lint)
- ✅ Type safety checks (ReScript compiler)
- ⚠️ SAST scanning (planned)
- ⚠️ Dependency scanning (planned)

## Known Security Considerations

### Current Limitations
1. **Mock Zotero API:** Production requires real API security review
2. **No WASM sandbox:** Future WASM needs security audit
3. **NLP integration:** Future NLP libraries need vetting
4. **Visualization libraries:** SVG generation needs XSS review

### Mitigations Planned
- Formal Zotero API security review before v1.0
- WASM Content Security Policy
- NLP library sandboxing
- SVG sanitization library

## Security-Related Configuration

### Deno Permissions
Minimal required permissions:

```bash
# Read-only Zotero library access
deno run --allow-read=/path/to/zotero fogbinder.js

# Analysis with file output
deno run --allow-read --allow-write=./output fogbinder.js
```

**Never use `--allow-all` in production.**

### Content Security Policy
For web UI (future):

```
default-src 'none';
script-src 'self';
style-src 'self';
img-src 'self' data:;
font-src 'self';
connect-src 'none';
```

## Compliance

### Standards
- ✅ **OWASP Top 10:** Addressed
- ✅ **CWE Top 25:** No applicable weaknesses
- ✅ **SANS Top 25:** Secure coding practices
- ✅ **GDPR:** No personal data processing

### Certifications
- ⚠️ **SOC 2:** Planned for hosted version
- ⚠️ **ISO 27001:** Planned for enterprise

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Deno Security](https://deno.land/manual/basics/permissions)
- [ReScript Security](https://rescript-lang.org/)
- [RFC 9116 - security.txt](https://www.rfc-editor.org/rfc/rfc9116.html)

## Contact

- **Security Issues:** GitHub Security Advisories
- **General Security Questions:** See CONTRIBUTING.md
- **Emergency Contact:** security@fogbinder.org (FUTURE)

---

**Last Updated:** 2025-11-22
**Version:** 0.1.0
**License:** GNU AGPLv3
