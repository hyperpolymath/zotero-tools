# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 8.x     | :white_check_mark: |
| 7.x     | :white_check_mark: |
| 6.x     | :x:                |
| < 6.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in Zotpress, please report it responsibly.

### How to Report

1. **Do NOT create a public GitHub issue** for security vulnerabilities.

2. **Email**: Send details to `security@hyperpolymath.org` with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes (optional)

3. **GitHub Security Advisories**: You can also use [GitHub's private vulnerability reporting](https://github.com/hyperpolymath/zotpress/security/advisories/new) to submit a report directly.

### What to Expect

- **Acknowledgment**: We will acknowledge receipt within 48 hours.
- **Assessment**: We will assess the vulnerability and determine its severity within 7 days.
- **Resolution Timeline**:
  - Critical vulnerabilities: Patch within 48 hours
  - High severity: Patch within 7 days
  - Medium severity: Patch within 30 days
  - Low severity: Patch in next regular release

### After Resolution

- We will notify you when the fix is released
- We will credit you in the security advisory (unless you prefer to remain anonymous)
- A CVE will be requested for significant vulnerabilities

## Security Measures

This project implements the following security practices:

- **Static Analysis**: PHPStan Level 6, Psalm, and WordPress PHPCS standards
- **Dependency Scanning**: Automated via Dependabot and Roave Security Advisories
- **Secret Scanning**: TruffleHog integration in CI/CD
- **Code Scanning**: GitHub CodeQL for JavaScript/TypeScript and workflow analysis
- **OSSF Scorecard**: Regular security posture assessments

## Scope

This security policy applies to:
- The main Zotpress WordPress plugin
- Official JavaScript/ReScript frontend components
- GitHub Actions workflows in this repository

Third-party dependencies are managed through their respective security channels.
