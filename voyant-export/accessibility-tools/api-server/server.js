/**
 * Accessibility Monitoring API
 * Like report-uri.com but for accessibility
 *
 * Features:
 * - Receive accessibility violation reports
 * - Provide dashboard for site owners
 * - Track improvement over time
 * - Alert on regressions
 * - Public API for scanning
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// In-memory storage (use PostgreSQL in production)
const reports = new Map();
const scans = new Map();
const sites = new Map();

/**
 * Public scanning endpoint (like securityheaders.com API)
 */
app.post('/api/scan', async (req, res) => {
  const { url } = req.body;

  if (!url) {
    return res.status(400).json({ error: 'URL is required' });
  }

  // Validate URL
  try {
    new URL(url);
  } catch (e) {
    return res.status(400).json({ error: 'Invalid URL' });
  }

  try {
    // In production, this would:
    // 1. Fetch the page
    // 2. Run accessibility tests (axe, pa11y, lighthouse)
    // 3. Analyze results
    // 4. Store in database
    // 5. Return results

    const scanResult = await performAccessibilityScan(url);

    // Store scan
    const scanId = generateId();
    scans.set(scanId, {
      id: scanId,
      url,
      ...scanResult,
      timestamp: Date.now()
    });

    res.json({
      ...scanResult,
      scan_id: scanId,
      dashboard_url: `https://monitor.accessibility-everywhere.org/scans/${scanId}`
    });

  } catch (error) {
    console.error('Scan error:', error);
    res.status(500).json({ error: 'Scan failed' });
  }
});

/**
 * Reporting endpoint (like report-uri.com)
 * Sites send violation reports here
 */
app.post('/api/report', async (req, res) => {
  const report = req.body;

  // Validate report structure
  if (!report || !report.site || !report.violations) {
    return res.status(400).json({ error: 'Invalid report format' });
  }

  try {
    const reportId = generateId();
    const domain = extractDomain(report.site.url);

    // Store report
    reports.set(reportId, {
      id: reportId,
      ...report,
      received_at: Date.now()
    });

    // Update site statistics
    if (!sites.has(domain)) {
      sites.set(domain, {
        domain,
        first_seen: Date.now(),
        total_reports: 0,
        violations: []
      });
    }

    const site = sites.get(domain);
    site.total_reports++;
    site.last_report = Date.now();
    site.violations.push(...report.violations);
    sites.set(domain, site);

    res.json({
      status: 'received',
      report_id: reportId,
      processed: true,
      dashboard_url: `https://monitor.accessibility-everywhere.org/reports/${reportId}`,
      message: 'Thank you for helping improve accessibility'
    });

  } catch (error) {
    console.error('Report processing error:', error);
    res.status(500).json({ error: 'Failed to process report' });
  }
});

/**
 * Get site dashboard data
 */
app.get('/api/sites/:domain', async (req, res) => {
  const { domain } = req.params;

  if (!sites.has(domain)) {
    return res.status(404).json({ error: 'Site not found' });
  }

  const site = sites.get(domain);

  // Calculate statistics
  const stats = calculateSiteStats(site);

  res.json({
    domain,
    ...stats,
    dashboard_url: `https://monitor.accessibility-everywhere.org/sites/${domain}`
  });
});

/**
 * Get aggregated statistics (for public scoreboard)
 */
app.get('/api/stats/top-sites', async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 100, 1000);
  const category = req.query.category || 'all';

  // In production, this would query a database
  // For now, return mock data

  const topSites = generateTopSitesData(limit, category);

  res.json({
    category,
    total_sites: topSites.length,
    last_updated: Date.now(),
    sites: topSites
  });
});

/**
 * Get adoption metrics (like Scott Helme's adoption tracking)
 */
app.get('/api/stats/adoption', async (req, res) => {
  // In production, this would track:
  // - How many of top 1M sites have accessibility headers
  // - How many have /.well-known/accessibility
  // - How many use our monitoring
  // - Trend over time

  res.json({
    total_scanned: 1000000,
    last_scan: '2024-01-15',
    metrics: {
      accessibility_header: {
        count: 15234,
        percentage: 1.52,
        trend_30d: '+12.5%'
      },
      well_known_endpoint: {
        count: 8456,
        percentage: 0.85,
        trend_30d: '+8.2%'
      },
      wcag_aa_compliant: {
        count: 125678,
        percentage: 12.57,
        trend_30d: '+3.1%'
      },
      monitoring_enabled: {
        count: 5432,
        percentage: 0.54,
        trend_30d: '+45.2%'
      }
    },
    historical: generateAdoptionHistory()
  });
});

/**
 * Verify badge/certificate
 */
app.get('/api/verify/:domain', async (req, res) => {
  const { domain } = req.params;

  // In production, check database for verified sites
  const verified = sites.has(domain);

  if (!verified) {
    return res.json({
      domain,
      verified: false,
      message: 'Site not verified'
    });
  }

  const site = sites.get(domain);
  const stats = calculateSiteStats(site);

  res.json({
    domain,
    verified: stats.score >= 85,
    level: stats.score >= 95 ? 'AAA' : stats.score >= 85 ? 'AA' : 'A',
    standard: 'WCAG 2.1',
    score: stats.score,
    last_tested: site.last_report,
    expires: site.last_report + (90 * 24 * 60 * 60 * 1000), // 90 days
    badge_url: `https://accessibility-everywhere.org/badge/verified-${stats.level}.svg`,
    certificate_url: `https://accessibility-everywhere.org/cert/${domain}.pdf`
  });
});

/**
 * Helper Functions
 */

async function performAccessibilityScan(url) {
  // In production, would use axe, pa11y, lighthouse
  // For MVP, return realistic demo data

  const score = Math.floor(Math.random() * 50) + 40;

  return {
    overall: score,
    wcag: {
      a: score >= 75,
      aa: score >= 85,
      aaa: score >= 95
    },
    categories: {
      'Images & Media': Math.floor(Math.random() * 40) + 60,
      'Forms & Inputs': Math.floor(Math.random() * 40) + 60,
      'Navigation': Math.floor(Math.random() * 40) + 60,
      'Color & Contrast': Math.floor(Math.random() * 40) + 60,
      'Semantic HTML': Math.floor(Math.random() * 40) + 60,
      'ARIA': Math.floor(Math.random() * 40) + 60,
      'Keyboard Access': Math.floor(Math.random() * 40) + 60
    },
    issues: generateSampleIssues(),
    timestamp: Date.now(),
    scanType: 'comprehensive'
  };
}

function calculateSiteStats(site) {
  const violations = site.violations || [];
  const criticalCount = violations.filter(v => v.severity === 'critical').length;
  const seriousCount = violations.filter(v => v.severity === 'serious').length;

  const score = Math.max(0, 100 - (criticalCount * 10) - (seriousCount * 5));

  return {
    score,
    level: score >= 95 ? 'AAA' : score >= 85 ? 'AA' : score >= 75 ? 'A' : 'Non-compliant',
    total_violations: violations.length,
    critical: criticalCount,
    serious: seriousCount,
    last_check: site.last_report,
    trend: 'improving' // Would calculate from historical data
  };
}

function generateTopSitesData(limit, category) {
  const sites = [];

  const domains = [
    'bbc.com', 'gov.uk', 'apple.com', 'microsoft.com', 'github.com',
    'wikipedia.org', 'mozilla.org', 'w3.org', 'cloudflare.com', 'google.com'
  ];

  for (let i = 0; i < Math.min(limit, domains.length); i++) {
    const score = Math.floor(Math.random() * 40) + 60;
    sites.push({
      rank: i + 1,
      domain: domains[i],
      score,
      level: score >= 95 ? 'AAA' : score >= 85 ? 'AA' : score >= 75 ? 'A' : 'Non-compliant',
      last_tested: Date.now() - Math.floor(Math.random() * 30 * 24 * 60 * 60 * 1000),
      trend: Math.random() > 0.5 ? 'improving' : 'stable'
    });
  }

  return sites.sort((a, b) => b.score - a.score);
}

function generateAdoptionHistory() {
  const history = [];
  const now = Date.now();

  for (let i = 12; i >= 0; i--) {
    const month = new Date(now - (i * 30 * 24 * 60 * 60 * 1000));
    history.push({
      date: month.toISOString().split('T')[0],
      accessibility_header: Math.floor(1000 + (i * 100)),
      well_known: Math.floor(500 + (i * 50)),
      wcag_aa: Math.floor(100000 + (i * 2000))
    });
  }

  return history;
}

function generateSampleIssues() {
  const issues = [
    {
      type: 'missing-alt',
      severity: 'serious',
      wcag: '1.1.1',
      description: 'Images missing alternative text',
      count: Math.floor(Math.random() * 10) + 1
    },
    {
      type: 'color-contrast',
      severity: 'serious',
      wcag: '1.4.3',
      description: 'Insufficient color contrast',
      count: Math.floor(Math.random() * 15) + 1
    }
  ];

  return issues;
}

function extractDomain(url) {
  try {
    return new URL(url).hostname;
  } catch (e) {
    return url;
  }
}

function generateId() {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: Date.now() });
});

// Start server
app.listen(PORT, () => {
  console.log(`Accessibility Monitoring API running on port ${PORT}`);
  console.log(`
  Endpoints:
    POST /api/scan - Scan a website
    POST /api/report - Report accessibility violations
    GET  /api/sites/:domain - Get site dashboard
    GET  /api/stats/top-sites - Get top sites scoreboard
    GET  /api/stats/adoption - Get adoption metrics
    GET  /api/verify/:domain - Verify badge
  `);
});

module.exports = app;
