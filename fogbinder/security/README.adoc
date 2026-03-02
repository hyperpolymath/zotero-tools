# Security Audit Framework

Comprehensive security audit preparation for Fogbinder (RSR Platinum requirement).

## Purpose

This framework provides:
1. **Audit checklists** - Systematic security review
2. **Automated scans** - Continuous security testing
3. **Documentation** - Security posture evidence
4. **Compliance** - RSR Platinum + industry standards

## Components

### 1. Audit Checklist (`AUDIT_CHECKLIST.md`)

Comprehensive 60+ point security checklist covering:

- **Code Security** (10 dimensions from SECURITY.md)
  - Input validation
  - Memory safety
  - Type safety
  - Offline-first
  - Data privacy
  - Dependency security
  - Access control
  - Error handling
  - Cryptography
  - Build security

- **OWASP Top 10**
  - Injection
  - Broken Authentication
  - Sensitive Data Exposure
  - XXE
  - Broken Access Control
  - Security Misconfiguration
  - XSS
  - Insecure Deserialization
  - Known Vulnerabilities
  - Logging & Monitoring

- **Supply Chain Security**
  - Dependency provenance
  - Build provenance
  - SBOM (Software Bill of Materials)

- **Secure Development Lifecycle**
  - Threat modeling
  - Code review
  - Security testing

- **Incident Response**
  - Vulnerability disclosure
  - IR plan

- **Compliance**
  - License compliance
  - Privacy compliance

### 2. Automated Security Scans

#### Dependency Scanning

Check for known vulnerabilities:

```bash
# Deno dependencies
deno task check-deps

# npm dependencies (if any)
npm audit

# Specific tools
deno run --allow-net https://deno.land/x/audit/mod.ts
```

#### Static Analysis

Automated code security scanning:

```bash
# TypeScript/JavaScript linting with security rules
deno lint

# Type checking (catches many security issues)
deno check src/**/*.ts

# Custom security grep patterns
just security-scan
```

#### License Scanning

Verify license compatibility:

```bash
# Check all dependency licenses
deno task check-licenses

# Verify AGPLv3 compliance
just license-check
```

### 3. Security Testing

#### Manual Security Testing

1. **Input Validation:**
   ```bash
   # Test with malicious inputs
   deno test src/**/*.test.ts --filter "input"
   ```

2. **XSS Prevention:**
   ```bash
   # Test SVG generation with XSS payloads
   deno test src/engine/FogTrailVisualizer.test.ts
   ```

3. **Injection Prevention:**
   ```bash
   # Test with injection attempts
   # (Fogbinder has no DB/command execution, low risk)
   ```

#### Automated Security Tests

Property-based tests verify security properties:

```bash
# Run property tests (includes security properties)
deno test --allow-all "**/*.property.test.ts"
```

### 4. Audit Preparation

#### Before External Audit

1. **Self-assessment:**
   ```bash
   cp security/AUDIT_CHECKLIST.md security/audits/self-assessment-$(date +%Y-%m-%d).md
   # Fill out checklist
   ```

2. **Gather evidence:**
   ```bash
   # Run all security scans
   just security-scan > security/audits/scan-results-$(date +%Y-%m-%d).txt

   # Run dependency audit
   deno task check-deps > security/audits/deps-audit-$(date +%Y-%m-%d).txt

   # Generate SBOM
   just generate-sbom > security/audits/sbom-$(date +%Y-%m-%d).json
   ```

3. **Review findings:**
   - Address critical issues
   - Document acceptable risks
   - Prepare mitigation plans

#### During External Audit

1. **Provide access:**
   - Source code repository
   - Build environment
   - Documentation

2. **Support auditor:**
   - Answer questions
   - Clarify architecture
   - Demonstrate features

3. **Track findings:**
   - Use GitHub Security Advisories
   - Prioritize by severity
   - Assign remediation owners

#### After Audit

1. **Remediate findings:**
   - Fix critical issues immediately
   - Schedule high-priority fixes
   - Document accepted risks

2. **Update documentation:**
   - Add audit report to `security/audits/`
   - Update SECURITY.md if needed
   - Share lessons learned

3. **Continuous improvement:**
   - Integrate findings into SDL
   - Update security tests
   - Enhance automation

## Security Scan Commands

### Comprehensive Security Scan

```bash
just security-scan
```

This runs:
- Dependency vulnerability scan
- Static analysis
- License compliance check
- Secret detection
- Custom security rules

### Individual Scans

```bash
# Dependency scan
deno task check-deps

# Lint for security issues
deno lint --rules-include=no-eval,no-implicit-coercion

# Type safety check
deno check src/**/*.ts

# Search for potential secrets
grep -r "API_KEY\|SECRET\|PASSWORD" src/ || echo "No secrets found"

# Search for dangerous functions
grep -r "eval\|innerHTML\|document.write" src/ || echo "No dangerous functions found"
```

## Security Testing Integration

### CI/CD

Security scans run automatically in CI:

```yaml
# .github/workflows/ci.yml
- name: Security Audit
  run: |
    deno task check-deps
    deno lint
    just security-scan
```

### Pre-commit Hooks

Add security checks to pre-commit:

```bash
# .git/hooks/pre-commit
#!/bin/bash
set -e

echo "Running security checks..."

# Check for secrets
if grep -r "API_KEY\|SECRET\|PASSWORD" src/; then
  echo "❌ Potential secrets detected!"
  exit 1
fi

# Run linter
deno lint

echo "✓ Security checks passed"
```

## Threat Model

### Attack Surface

1. **Input vectors:**
   - User-provided source texts
   - Language game contexts
   - Configuration options

2. **Output vectors:**
   - SVG visualization (XSS risk)
   - JSON export
   - Console logs

3. **External dependencies:**
   - ReScript compiler
   - Deno runtime
   - npm packages (minimal)

### Trust Boundaries

1. **Trusted:**
   - Source code (reviewed)
   - Build environment (reproducible)
   - ReScript/Deno runtime

2. **Untrusted:**
   - User-provided inputs
   - Zotero item data
   - External citations

### Known Attack Vectors

| Vector | Risk | Mitigation |
|--------|------|------------|
| XSS in SVG output | Medium | HTML encoding, CSP |
| Malicious input strings | Low | Length limits, sanitization |
| Dependency vulnerabilities | Low | Regular audits, minimal deps |
| Supply chain attacks | Low | Locked versions, Nix builds |

### Security Assumptions

1. Fogbinder runs in user's local environment (not server)
2. No network access required (offline-first)
3. No PII processed
4. Zotero data trusted (user's own library)

## Incident Response

### Reporting Vulnerabilities

See `.well-known/security.txt` and `SECURITY.md`.

**Contact:** https://github.com/Hyperpolymath/fogbinder/security/advisories/new

**Response SLAs:**
- Critical: 24 hours
- High: 7 days
- Medium: 30 days
- Low: 90 days

### Handling Vulnerabilities

1. **Triage** (within 24h)
   - Assess severity
   - Verify reproducibility
   - Assign owner

2. **Develop fix** (per SLA)
   - Create patch
   - Test thoroughly
   - Review security implications

3. **Disclose** (coordinated)
   - Notify users
   - Publish advisory
   - Credit reporter

4. **Post-incident review**
   - Root cause analysis
   - Process improvements
   - Documentation updates

## Compliance Checklist

### RSR Platinum Requirements

- [x] 100% test coverage
- [x] Formal verification (TLA+)
- [x] Property-based testing
- [x] Performance benchmarks
- [x] Security audit framework ← (this)
- [ ] Security audit completed (pending)
- [ ] Production deployment preparation

### Industry Standards

- [x] OWASP Top 10 coverage
- [x] Supply chain security (SBOM, provenance)
- [x] Vulnerability disclosure (security.txt, RFC 9116)
- [x] Secure development lifecycle
- [ ] External security audit (recommended)
- [ ] Penetration testing (optional)

## Further Reading

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [SLSA Framework](https://slsa.dev/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Supply Chain Levels for Software Artifacts](https://slsa.dev/)

---

**Last Updated:** 2025-11-23
**License:** GNU AGPLv3
**RSR Tier:** Platinum Requirement
