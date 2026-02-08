# Proposed Accessibility Standards & Protocols
## Making Accessibility as Easy as Security Headers

Inspired by Scott Helme's work on security headers and the success of HTTPS Everywhere, we propose standardized, easy-to-implement mechanisms for declaring and enforcing web accessibility.

---

## 1. Accessibility-Policy HTTP Header

### Problem
Sites have no standardized way to declare their accessibility commitments or receive violation reports.

### Solution: `Accessibility-Policy` HTTP Header

```http
Accessibility-Policy: level=AA; report-uri=https://example.com/a11y-report; enforce
```

#### Directive Options:

```http
# Basic declaration
Accessibility-Policy: level=AA

# With reporting endpoint (like CSP report-uri)
Accessibility-Policy: level=AA; report-uri=https://accessibility-monitor.example.com/report

# Report-only mode (like CSP report-only)
Accessibility-Policy-Report-Only: level=AAA; report-uri=https://example.com/reports

# With multiple directives
Accessibility-Policy: level=AA;
                      report-uri=https://example.com/a11y-report;
                      require-contrast=4.5;
                      require-alt-text;
                      require-labels;
                      require-landmarks;
                      enforce
```

#### Directives Explained:

- **`level=<A|AA|AAA>`** - Target WCAG compliance level
- **`report-uri=<url>`** - Endpoint for accessibility violation reports
- **`enforce`** - Browser should actively help enforce (future)
- **`require-contrast=<ratio>`** - Minimum contrast ratio
- **`require-alt-text`** - All images must have alt attributes
- **`require-labels`** - All form inputs must have labels
- **`require-landmarks`** - Require semantic landmarks
- **`require-lang`** - Require language declaration
- **`require-headings`** - Require proper heading structure

#### Browser Integration (Future Vision):

```javascript
// Browsers would send violation reports like CSP violations
{
  "accessibility-policy-violation": {
    "policy": "require-alt-text",
    "violated-directive": "require-alt-text",
    "element": "img",
    "selector": "div.hero > img.banner",
    "wcag": "1.1.1",
    "severity": "serious",
    "url": "https://example.com/page",
    "timestamp": "2024-01-15T12:00:00Z"
  }
}
```

---

## 2. /.well-known/accessibility Resource

### Problem
No standardized location for accessibility statements and machine-readable compliance data.

### Solution: `/.well-known/accessibility` endpoint

Similar to /.well-known/security.txt, this provides machine-readable accessibility information.

```json
{
  "version": "1.0",
  "last_updated": "2024-01-15",
  "conformance": {
    "level": "AA",
    "standard": "WCAG 2.1",
    "partial_conformance": false,
    "exceptions": []
  },
  "statement": "https://example.com/accessibility-statement",
  "contact": {
    "email": "accessibility@example.com",
    "web": "https://example.com/accessibility-feedback"
  },
  "monitoring": {
    "last_audit": "2024-01-01",
    "next_audit": "2024-07-01",
    "auditor": "Example Accessibility Services",
    "report": "https://example.com/accessibility-audit-2024.pdf"
  },
  "assistive_tech_tested": [
    "NVDA 2023.3",
    "JAWS 2024",
    "VoiceOver (macOS Sonoma)",
    "TalkBack (Android 14)"
  ],
  "remediation": {
    "contact_response_time": "2 business days",
    "issue_resolution_commitment": "30 days"
  }
}
```

#### Text Format Alternative (like security.txt):

```text
# Accessibility Information for example.com
# Specification: https://accessibility-everywhere.org/well-known-spec

Conformance-Level: WCAG-2.1-AA
Last-Audit: 2024-01-01
Statement: https://example.com/accessibility
Contact: accessibility@example.com
Expires: 2025-01-15
```

---

## 3. HTML Meta Tag: Accessibility Declaration

### For sites that can't modify HTTP headers

```html
<meta name="accessibility-level" content="WCAG-2.1-AA">
<meta name="accessibility-report-uri" content="https://example.com/a11y-report">
<meta name="accessibility-statement" content="https://example.com/accessibility">
```

Or using JSON-LD:

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Example Site",
  "accessibilityControl": ["fullKeyboardControl", "fullMouseControl"],
  "accessibilityFeature": [
    "alternativeText",
    "longDescription",
    "captions",
    "transcript",
    "structuralNavigation",
    "highContrastDisplay",
    "resizeText"
  ],
  "accessibilityHazard": "none",
  "accessibilityAPI": "ARIA",
  "wcagCompliance": "AA"
}
</script>
```

---

## 4. DNS TXT Record for Accessibility

### Problem
No way to verify ownership and commitment at DNS level.

### Solution: DNS TXT record (like SPF, DKIM for email)

```dns
_accessibility.example.com. IN TXT "v=a11y1; level=AA; report=https://example.com/report"
```

**Benefits:**
- Hard to fake (requires DNS access)
- Easy to verify programmatically
- Can be used by search engines for ranking
- Demonstrates organizational commitment

---

## 5. Accessibility Reporting API Endpoint Specification

### Like report-uri.com for CSP, but for accessibility

#### Standard Report Format:

```json
POST /accessibility-report
Content-Type: application/json

{
  "version": "1.0",
  "report_id": "uuid-v4-here",
  "site": {
    "url": "https://example.com/page",
    "domain": "example.com"
  },
  "user_agent": {
    "browser": "Chrome 120",
    "os": "Windows 11",
    "assistive_tech": "NVDA 2023.3"
  },
  "violations": [
    {
      "id": "uuid-v4-here",
      "wcag": "1.1.1",
      "level": "A",
      "type": "missing-alt-text",
      "severity": "serious",
      "element": {
        "selector": "div.hero > img.banner",
        "html": "<img src=\"banner.jpg\">",
        "xpath": "/html/body/div[1]/img[1]"
      },
      "impact": "Screen reader users cannot understand the image content",
      "recommendation": "Add descriptive alt text to the image",
      "detected_by": "automated-scan",
      "timestamp": "2024-01-15T12:00:00Z"
    }
  ],
  "scan_metadata": {
    "scanner": "accessibility-everywhere-extension",
    "scanner_version": "1.0.0",
    "scan_type": "automated",
    "rules_version": "WCAG-2.1"
  }
}
```

#### Response Format:

```json
{
  "status": "received",
  "report_id": "uuid-v4-here",
  "processed": true,
  "dashboard_url": "https://monitor.accessibility-everywhere.org/reports/uuid",
  "message": "Thank you for helping improve accessibility"
}
```

---

## 6. Accessibility Badges & Verification

### Level 1: Self-Declared Badge

```html
<a href="https://accessibility-everywhere.org/verify/example.com">
  <img src="https://accessibility-everywhere.org/badge/wcag-aa.svg"
       alt="WCAG 2.1 AA Conformant">
</a>
```

### Level 2: Verified Badge (Requires testing)

Sites that pass automated + manual testing get a verified badge:

```html
<a href="https://accessibility-everywhere.org/verified/example.com/2024-01">
  <img src="https://accessibility-everywhere.org/badge/verified-aa.svg"
       alt="Verified WCAG 2.1 AA Conformant - January 2024">
</a>
```

#### Badge Verification API:

```http
GET /api/verify/example.com
```

```json
{
  "domain": "example.com",
  "verified": true,
  "level": "AA",
  "standard": "WCAG 2.1",
  "score": 94,
  "last_tested": "2024-01-15",
  "expires": "2024-04-15",
  "badge_url": "https://accessibility-everywhere.org/badge/verified-aa.svg",
  "certificate_url": "https://accessibility-everywhere.org/cert/example.com.pdf"
}
```

---

## 7. Browser Extension Auto-Detection Protocol

### Problem
How do browser extensions know to scan a page?

### Solution: Meta tag trigger

```html
<meta name="accessibility-scan-requested" content="true">
<meta name="accessibility-scan-report-to" content="https://example.com/reports">
```

When the extension sees this, it automatically scans and sends results to the specified endpoint.

---

## 8. Search Engine Integration Proposal

### Accessibility Signals for Ranking

Search engines could use these signals:

1. **`Accessibility-Policy` header present** → +5 ranking points
2. **Verified WCAG AA compliance** → +10 ranking points
3. **`/.well-known/accessibility` endpoint exists** → +5 ranking points
4. **DNS TXT record present** → +5 ranking points
5. **User reports of good accessibility** → +10 ranking points
6. **Low violation report rate** → +10 ranking points
7. **Consistent monitoring/improvement** → +5 ranking points

#### Rich Snippets for Accessible Sites:

```json
{
  "@type": "SearchAction",
  "accessibility": {
    "badge": "WCAG-AA-Verified",
    "last_tested": "2024-01-15",
    "score": 94
  }
}
```

Would display in search results as:
```
Example Site
https://example.com
✓ Accessibility Verified (94/100)
This site is verified to meet WCAG 2.1 AA standards
```

---

## 9. GitHub Repository Metadata

### For open source projects

```yaml
# .github/accessibility.yml
version: 1.0

commitment:
  level: WCAG-2.1-AA
  target_score: 90

testing:
  automated:
    - axe-core
    - pa11y
    - lighthouse
  manual: true
  assistive_tech:
    - NVDA
    - JAWS
    - VoiceOver

ci:
  block_on_regression: true
  minimum_score: 85

reporting:
  endpoint: https://example.com/a11y-reports
  public_dashboard: https://example.com/accessibility

maintainers:
  accessibility:
    - "@accessibility-team"
```

---

## 10. npm/Package Manager Integration

### package.json accessibility metadata

```json
{
  "name": "my-component-library",
  "accessibility": {
    "wcag_level": "AA",
    "tested_with": ["screen-reader", "keyboard-only"],
    "documentation": "https://example.com/a11y-docs",
    "issues": "https://github.com/example/issues?label=accessibility"
  },
  "scripts": {
    "test:a11y": "accessibility-test",
    "audit:a11y": "accessibility-audit"
  }
}
```

npm could display accessibility badges on package pages, similar to downloads/version badges.

---

## Implementation Timeline

### Phase 1: Specification & Tooling (Months 1-6)

1. Publish formal specifications for:
   - Accessibility-Policy header
   - /.well-known/accessibility format
   - Report API specification
   - Badge verification system

2. Build reference implementations:
   - Node.js middleware for headers
   - WordPress/Drupal plugins
   - Static site generators (Hugo, Jekyll, etc.)
   - CDN integration (CloudFlare Workers)

3. Launch validation tools:
   - Online header validator
   - Badge verification API
   - /.well-known validator

### Phase 2: Ecosystem Adoption (Months 7-12)

1. Browser extension integration
2. npm ecosystem integration
3. GitHub integration
4. CDN partnerships (CloudFlare, Fastly, etc.)
5. CMS plugin ecosystem

### Phase 3: Search Engine Engagement (Months 13-24)

1. Demonstrate adoption metrics
2. Publish research on correlation with quality
3. Proposal to search engines
4. Rich snippet integration
5. Ranking algorithm integration

---

## Why This Will Work

### Precedents:

1. **Security Headers**
   - Simple to implement
   - Clear validation
   - Scott Helme's securityheaders.com drove adoption

2. **HTTPS Everywhere**
   - Browser extension drove demand
   - Let's Encrypt removed barriers
   - Now 95%+ of web traffic is HTTPS

3. **robots.txt, .well-known/**
   - Simple text files
   - Easy to implement
   - Universal adoption

### Key Success Factors:

1. **Dead Simple Implementation**
   ```nginx
   # Just add one line to nginx config
   add_header Accessibility-Policy "level=AA; report-uri=/a11y-report";
   ```

2. **Immediate Value**
   - Badge for marketing
   - Potential SEO boost
   - User trust
   - Legal compliance

3. **Network Effects**
   - More adoption → more pressure on laggards
   - Search engines notice
   - Industry standards emerge

4. **Low Barrier to Entry**
   - No cost
   - Minimal technical requirement
   - Can start with self-declaration

---

## Call to Action

### For Developers
Add these headers/files to your sites today. Even without browser/search engine support, you're declaring commitment.

### For Organizations
Partner with us to make this a standard. Internet Society, W3C, and browser vendors are key.

### For Search Engines
This provides a clear, verifiable signal of quality and user care. Use it in rankings.

### For Users
Demand accessibility. Use the browser extension. Support sites that care.

---

## Resources

- Specification Documents: [Coming Soon]
- Reference Implementations: [Coming Soon]
- Validation Tools: [Coming Soon]
- Community Discussion: [GitHub]

---

*"Make accessibility as easy as adding a header. Make it as expected as HTTPS."*
