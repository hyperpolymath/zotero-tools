# Accessibility Everywhere

**Making the web accessible to everyone through technical tools, standards, and advocacy**

Inspired by successful movements like HTTPS Everywhere, Let's Encrypt, and Scott Helme's security work (securityheaders.com, report-uri.com), this project provides a comprehensive platform to drive digital accessibility adoption.

---

## 🎯 Mission

96% of the top million websites have accessibility problems (WebAIM 2024), denying access to vital information for people with disabilities. We're changing this through:

1. **Free technical infrastructure** (à la Let's Encrypt)
2. **User empowerment tools** (à la HTTPS Everywhere)
3. **Public accountability** (à la WebAIM reports)
4. **Developer enablement** (modern DevOps integration)
5. **Strategic advocacy** (multi-stakeholder pressure)

---

## 📦 What's Included

### 1. Browser Extension (Like HTTPS Everywhere)

**`browser-extension/`**

Real-time accessibility scoring for every website you visit.

**Features:**
- Badge showing accessibility score (0-100)
- WCAG A/AA/AAA compliance indicators
- One-click detailed reports
- Issue reporting to site owners
- Developer mode with inline hints
- Privacy-respecting (local-first testing)

**Install:**
```bash
cd browser-extension
# Load unpacked extension in Chrome/Firefox
```

### 2. Testing Dashboard (Like securityheaders.com)

**`dashboard/`**

Instant accessibility testing for any website.

**Features:**
- Enter any URL, get instant score
- WCAG 2.1 compliance checking
- Detailed issue breakdown
- Shareable reports
- Public scoreboard of top sites

**Try it:**
```bash
cd dashboard
# Open index.html in browser
# Or deploy to Vercel/CloudFlare Pages
```

**Live Demo:** `https://accessibilityheaders.com` (when deployed)

### 3. Monitoring API (Like report-uri.com)

**`api-server/`**

Continuous accessibility monitoring and reporting.

**Features:**
- Receive accessibility violation reports
- Track improvements over time
- Alert on regressions
- Public API for scanning
- Dashboard for site owners

**Setup:**
```bash
cd api-server
npm install
npm start
```

**Endpoints:**
- `POST /api/scan` - Scan a website
- `POST /api/report` - Report violations
- `GET /api/sites/:domain` - Site dashboard
- `GET /api/stats/adoption` - Adoption metrics
- `GET /api/verify/:domain` - Verify badge

### 4. GitHub Action (CI/CD Integration)

**`github-action/`**

Test accessibility in your CI/CD pipeline.

**Usage:**
```yaml
- uses: accessibility-everywhere/test@v1
  with:
    url: ${{ steps.deploy.outputs.url }}
    min-score: 85
    wcag-level: AA
    fail-on-regression: true
```

**Features:**
- Automated testing on every PR
- Block merges below threshold
- PR comments with detailed results
- Track improvements over time

### 5. Adoption Tracker

**`adoption-tracker/`**

Track accessibility adoption across top 1M websites (like Scott Helme's tracking).

**Features:**
- Scan top N sites for accessibility features
- Track adoption of:
  - Accessibility-Policy headers
  - /.well-known/accessibility endpoints
  - WCAG compliance levels
  - Overall scores
- Generate trend reports
- Public data for researchers

**Run:**
```bash
cd adoption-tracker
npm install
node scanner.js 1000  # Scan top 1000 sites
```

---

## 🚀 Quick Start

### For Users

1. **Install Browser Extension**
   - Download from `browser-extension/`
   - Load unpacked extension
   - Visit any website to see its accessibility score

2. **Test Your Site**
   - Visit the dashboard (or open `dashboard/index.html`)
   - Enter your URL
   - Get instant report

### For Developers

1. **Add to CI/CD**
   ```yaml
   - uses: accessibility-everywhere/test@v1
     with:
       min-score: 80
   ```

2. **Implement Proposed Standards**
   ```http
   # Add HTTP header
   Accessibility-Policy: level=AA; report-uri=/a11y-report
   ```

3. **Create /.well-known/accessibility**
   ```json
   {
     "version": "1.0",
     "conformance": {
       "level": "AA",
       "standard": "WCAG 2.1"
     },
     "contact": {
       "email": "accessibility@example.com"
     }
   }
   ```

### For Site Owners

1. **Enable Monitoring**
   ```html
   <meta name="accessibility-scan-requested" content="true">
   <meta name="accessibility-scan-report-to" content="https://your-site.com/reports">
   ```

2. **Get Verified Badge**
   - Test your site
   - Achieve 85+ score
   - Apply for verification
   - Display badge:
   ```html
   <img src="https://accessibility-everywhere.org/badge/verified-aa.svg"
        alt="WCAG AA Verified">
   ```

---

## 📊 Proposed Standards

See [`PROPOSED_STANDARDS.md`](./PROPOSED_STANDARDS.md) for detailed specifications:

1. **Accessibility-Policy HTTP Header** (like CSP)
2. **/.well-known/accessibility** endpoint (like security.txt)
3. **HTML Meta Tags** for declarations
4. **DNS TXT Records** for verification
5. **Reporting API Specification**
6. **Badge/Verification System**
7. **Search Engine Integration Proposal**

---

## 📈 How This Drives Change

### Phase 1: Build Tools & Awareness (Months 1-6)

- ✅ Browser extension (like HTTPS Everywhere)
- ✅ Testing dashboard (like securityheaders.com)
- ✅ Monitoring API (like report-uri.com)
- ✅ Adoption tracker
- ✅ GitHub Action
- [ ] Public launch & media campaign

**Goal:** 100,000 extension users, 10,000 sites tested

### Phase 2: Ecosystem Adoption (Months 7-12)

- [ ] CMS plugins (WordPress, Drupal)
- [ ] CDN integration (CloudFlare, Fastly)
- [ ] Framework integration (Next.js, React, etc.)
- [ ] Badge program launch
- [ ] Partnership with W3C, Internet Society

**Goal:** 1,000 verified sites, measurable improvements

### Phase 3: Search Engine Integration (Months 13-24)

- [ ] Demonstrate adoption metrics
- [ ] Publish research on correlation with quality
- [ ] Formal proposal to Google, Bing, DuckDuckGo
- [ ] Rich snippet integration
- [ ] Ranking algorithm consideration

**Goal:** Accessibility as ranking factor

---

## 🤝 How You Can Help

### As a Developer

1. **Use the tools** - Add to your projects
2. **Contribute code** - PRs welcome
3. **Build integrations** - CMS plugins, frameworks
4. **Spread the word** - Blog, tweet, present

### As an Organization (like NUJ)

1. **Endorse the initiative** - Lend credibility
2. **Test member sites** - Use dashboard/tools
3. **Advocate** - Pressure on tech companies
4. **Connect** - Introduce to partners (Internet Society, etc.)
5. **Resource** - Support development/campaign

### As a User

1. **Install the extension** - Vote with usage
2. **Report issues** - Help sites improve
3. **Demand accessibility** - Contact sites with low scores
4. **Share** - Tell others about the tools

---

## 💡 Why This Will Succeed

### Proven Playbook

**HTTPS Adoption (2014-2024):**
- Started at <50% adoption
- HTTPS Everywhere browser extension drove demand
- Let's Encrypt removed cost barriers
- Now >95% of web traffic is HTTPS
- Google made it a ranking factor

**We're following the same path for accessibility:**
- Browser extension drives demand ✅
- Free tools remove barriers ✅
- Public scorecards create pressure ✅
- Adoption tracking shows progress ✅
- Search engine integration (coming) 🎯

### Multiple Pressure Points

1. **User Demand** - Extension shows scores, users notice
2. **Developer Tools** - Make it easy to fix
3. **Public Accountability** - Scoreboard shows laggards
4. **Economic Incentive** - Badge, SEO benefits
5. **Legal Compliance** - WCAG is law in many places
6. **Market Size** - 1.3 billion people with disabilities

---

## 📚 Documentation

- **[Initiative Overview](../ACCESSIBILITY_INITIATIVE.md)** - Comprehensive strategy
- **[Proposed Standards](./PROPOSED_STANDARDS.md)** - Technical specifications
- **[API Documentation](#)** - Coming soon
- **[Developer Guide](#)** - Coming soon

---

## 🛠️ Technology Stack

**Browser Extension:**
- Manifest V3
- axe-core for testing
- Vanilla JavaScript (no framework)

**Dashboard:**
- HTML/CSS/JavaScript
- D3.js for visualizations
- Static site (deployable to CDN)

**API Server:**
- Node.js / Express
- PostgreSQL (storage)
- Redis (caching)
- Puppeteer/Playwright (scanning)

**GitHub Action:**
- Node.js
- @actions/core, @actions/github
- axe-core, pa11y, lighthouse

**Adoption Tracker:**
- Node.js
- Playwright (browser automation)
- axe-core (testing)

---

## 📜 License

GPL-3.0 (compatible with Zotero, Voyant, and most FOSS)

All code is open source. All data is open. All standards are free to implement.

---

## 🌟 Inspiration & Credits

**Scott Helme:**
- [securityheaders.com](https://securityheaders.com) - Testing dashboard
- [report-uri.com](https://report-uri.com) - Monitoring service
- Security header adoption tracking

**EFF:**
- HTTPS Everywhere - Browser extension model
- Privacy Badger - User empowerment

**Let's Encrypt:**
- Free SSL certificates
- Automated infrastructure
- Massive ecosystem adoption

**WebAIM:**
- Annual accessibility reports
- Research and data
- WCAG advocacy

---

## 📞 Contact & Community

- **Issues:** [GitHub Issues](#)
- **Discussions:** [GitHub Discussions](#)
- **Email:** accessibility-everywhere@example.org
- **Twitter:** @a11yeverywhere
- **Matrix:** #accessibility-everywhere:matrix.org

---

## 🎯 Roadmap

### Now (Month 1-3)
- [x] Core tools built
- [ ] Public launch
- [ ] Browser extension in stores
- [ ] Dashboard deployed
- [ ] API hosted

### Next (Month 4-6)
- [ ] 100K extension users
- [ ] 10K sites tested
- [ ] First adoption report
- [ ] CMS plugins (WordPress, Drupal)
- [ ] CDN partnerships

### Later (Month 7-12)
- [ ] Badge program
- [ ] 500K extension users
- [ ] 1000 verified sites
- [ ] W3C/ISOC partnerships
- [ ] Search engine outreach

### Future (Month 13-24)
- [ ] Search engine integration
- [ ] Accessibility as ranking factor
- [ ] Measurable web-wide improvement
- [ ] Self-sustaining ecosystem

---

## 🙏 Acknowledgments

This initiative is inspired by the countless people working to make the web accessible, the developers building accessibility tools, the advocates fighting for digital rights, and the users with disabilities who deserve equal access to information.

**The web became secure through a combination of tools, standards, and market pressure. We can do the same for accessibility.**

---

*"The power of the Web is in its universality. Access by everyone regardless of disability is an essential aspect."*
— Tim Berners-Lee, W3C Director and inventor of the World Wide Web
