/**
 * Accessibility Adoption Tracker
 * Scans top N websites to track accessibility adoption
 * Like Scott Helme's tracking of security header adoption
 *
 * Tracks:
 * - Accessibility-Policy headers
 * - /.well-known/accessibility endpoints
 * - WCAG compliance levels
 * - Overall accessibility scores
 * - Trends over time
 */

const https = require('https');
const http = require('http');
const fs = require('fs');
const { URL } = require('url');
const { chromium } = require('playwright');

class AccessibilityAdoptionTracker {
  constructor(options = {}) {
    this.topSitesFile = options.topSitesFile || 'top-1m.csv';
    this.outputFile = options.outputFile || 'adoption-data.json';
    this.concurrency = options.concurrency || 10;
    this.timeout = options.timeout || 30000;
    this.results = [];
  }

  /**
   * Load top N sites from CSV (Tranco, Majestic, etc.)
   */
  loadTopSites(limit = 1000) {
    try {
      const data = fs.readFileSync(this.topSitesFile, 'utf-8');
      const lines = data.split('\n');

      const sites = lines
        .slice(0, limit)
        .map(line => {
          const [rank, domain] = line.split(',');
          return { rank: parseInt(rank), domain: domain?.trim() };
        })
        .filter(site => site.domain);

      console.log(`Loaded ${sites.length} sites`);
      return sites;
    } catch (error) {
      console.error('Error loading sites:', error.message);
      return this.getDefaultTopSites(limit);
    }
  }

  /**
   * Default list if CSV not available
   */
  getDefaultTopSites(limit) {
    const domains = [
      'google.com', 'youtube.com', 'facebook.com', 'twitter.com', 'instagram.com',
      'linkedin.com', 'reddit.com', 'wikipedia.org', 'amazon.com', 'netflix.com',
      'bbc.com', 'gov.uk', 'apple.com', 'microsoft.com', 'github.com',
      'stackoverflow.com', 'wordpress.org', 'mozilla.org', 'cloudflare.com', 'w3.org'
    ];

    return domains.slice(0, limit).map((domain, i) => ({
      rank: i + 1,
      domain
    }));
  }

  /**
   * Scan a single site for accessibility features
   */
  async scanSite(site) {
    const url = `https://${site.domain}`;

    console.log(`[${site.rank}] Scanning ${site.domain}...`);

    const result = {
      rank: site.rank,
      domain: site.domain,
      url,
      timestamp: new Date().toISOString(),
      features: {
        accessibility_header: false,
        well_known_endpoint: false,
        wcag_meta: false,
        dns_record: false
      },
      headers: {},
      accessibility_score: 0,
      wcag_level: null,
      issues: [],
      error: null
    };

    try {
      // Check HTTP headers
      const headers = await this.checkHeaders(url);
      result.headers = headers;

      // Check for Accessibility-Policy header
      if (headers['accessibility-policy']) {
        result.features.accessibility_header = true;
        result.accessibility_policy = headers['accessibility-policy'];
      }

      // Check for /.well-known/accessibility
      const wellKnown = await this.checkWellKnown(url);
      if (wellKnown) {
        result.features.well_known_endpoint = true;
        result.well_known_data = wellKnown;
        result.wcag_level = wellKnown.conformance?.level;
      }

      // Run accessibility scan
      const scanResult = await this.runAccessibilityScan(url);
      result.accessibility_score = scanResult.score;
      result.issues = scanResult.issues;
      result.wcag_level = result.wcag_level || scanResult.wcag_level;

      console.log(`[${site.rank}] ${site.domain}: Score ${result.accessibility_score}/100`);

    } catch (error) {
      result.error = error.message;
      console.error(`[${site.rank}] Error scanning ${site.domain}:`, error.message);
    }

    return result;
  }

  /**
   * Check HTTP headers for accessibility declarations
   */
  async checkHeaders(url) {
    return new Promise((resolve, reject) => {
      const urlObj = new URL(url);
      const client = urlObj.protocol === 'https:' ? https : http;

      const options = {
        method: 'HEAD',
        timeout: this.timeout,
        headers: {
          'User-Agent': 'AccessibilityAdoptionTracker/1.0'
        }
      };

      const req = client.request(url, options, (res) => {
        const headers = {};
        for (const [key, value] of Object.entries(res.headers)) {
          headers[key.toLowerCase()] = value;
        }
        resolve(headers);
      });

      req.on('error', reject);
      req.on('timeout', () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });

      req.end();
    });
  }

  /**
   * Check for /.well-known/accessibility endpoint
   */
  async checkWellKnown(baseUrl) {
    return new Promise((resolve) => {
      const url = `${baseUrl}/.well-known/accessibility`;

      const urlObj = new URL(url);
      const client = urlObj.protocol === 'https:' ? https : http;

      const options = {
        timeout: this.timeout,
        headers: {
          'User-Agent': 'AccessibilityAdoptionTracker/1.0'
        }
      };

      const req = client.get(url, options, (res) => {
        if (res.statusCode === 200) {
          let data = '';

          res.on('data', chunk => data += chunk);
          res.on('end', () => {
            try {
              const json = JSON.parse(data);
              resolve(json);
            } catch {
              resolve(null);
            }
          });
        } else {
          resolve(null);
        }
      });

      req.on('error', () => resolve(null));
      req.on('timeout', () => {
        req.destroy();
        resolve(null);
      });

      req.end();
    });
  }

  /**
   * Run accessibility scan using headless browser
   */
  async runAccessibilityScan(url) {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();

    try {
      await page.goto(url, { waitUntil: 'networkidle', timeout: this.timeout });

      // Inject axe-core and run scan
      await page.addScriptTag({ path: require.resolve('axe-core') });

      const results = await page.evaluate(() => {
        return new Promise((resolve) => {
          axe.run((err, results) => {
            if (err) {
              resolve({ violations: [], passes: [] });
            } else {
              resolve(results);
            }
          });
        });
      });

      await browser.close();

      // Calculate score
      const violations = results.violations || [];
      let score = 100;

      violations.forEach(v => {
        const impact = { critical: 10, serious: 5, moderate: 2, minor: 1 }[v.impact] || 1;
        score -= impact * v.nodes.length;
      });

      score = Math.max(0, score);

      // Determine WCAG level
      const wcagLevel = score >= 95 ? 'AAA' : score >= 85 ? 'AA' : score >= 75 ? 'A' : null;

      return {
        score,
        wcag_level: wcagLevel,
        issues: violations.slice(0, 10).map(v => ({
          type: v.id,
          impact: v.impact,
          count: v.nodes.length
        }))
      };

    } catch (error) {
      await browser.close();
      throw error;
    }
  }

  /**
   * Scan multiple sites with concurrency control
   */
  async scanBatch(sites) {
    const results = [];

    for (let i = 0; i < sites.length; i += this.concurrency) {
      const batch = sites.slice(i, i + this.concurrency);
      const batchResults = await Promise.allSettled(
        batch.map(site => this.scanSite(site))
      );

      batchResults.forEach(result => {
        if (result.status === 'fulfilled') {
          results.push(result.value);
        }
      });

      // Save progress periodically
      if (i % 100 === 0) {
        this.saveResults(results);
      }
    }

    return results;
  }

  /**
   * Save results to file
   */
  saveResults(results) {
    fs.writeFileSync(this.outputFile, JSON.stringify(results, null, 2));
    console.log(`Saved ${results.length} results to ${this.outputFile}`);
  }

  /**
   * Generate adoption statistics
   */
  generateStats(results) {
    const total = results.length;

    const stats = {
      total_scanned: total,
      scan_date: new Date().toISOString(),
      adoption: {
        accessibility_header: {
          count: results.filter(r => r.features.accessibility_header).length,
          percentage: 0
        },
        well_known_endpoint: {
          count: results.filter(r => r.features.well_known_endpoint).length,
          percentage: 0
        },
        wcag_aa_compliant: {
          count: results.filter(r => r.accessibility_score >= 85).length,
          percentage: 0
        },
        wcag_aaa_compliant: {
          count: results.filter(r => r.accessibility_score >= 95).length,
          percentage: 0
        }
      },
      scores: {
        average: 0,
        median: 0,
        min: 0,
        max: 0
      },
      top_10: [],
      bottom_10: []
    };

    // Calculate percentages
    Object.keys(stats.adoption).forEach(key => {
      const count = stats.adoption[key].count;
      stats.adoption[key].percentage = ((count / total) * 100).toFixed(2);
    });

    // Calculate score statistics
    const scores = results.map(r => r.accessibility_score).sort((a, b) => a - b);
    stats.scores.average = (scores.reduce((a, b) => a + b, 0) / total).toFixed(2);
    stats.scores.median = scores[Math.floor(total / 2)];
    stats.scores.min = scores[0];
    stats.scores.max = scores[scores.length - 1];

    // Top and bottom 10
    const sorted = [...results].sort((a, b) => b.accessibility_score - a.accessibility_score);
    stats.top_10 = sorted.slice(0, 10).map(r => ({
      domain: r.domain,
      score: r.accessibility_score
    }));
    stats.bottom_10 = sorted.slice(-10).map(r => ({
      domain: r.domain,
      score: r.accessibility_score
    }));

    return stats;
  }

  /**
   * Main run function
   */
  async run(limit = 1000) {
    console.log(`Starting accessibility adoption scan of top ${limit} sites`);

    const sites = this.loadTopSites(limit);
    const results = await this.scanBatch(sites);

    this.saveResults(results);

    const stats = this.generateStats(results);
    fs.writeFileSync('adoption-stats.json', JSON.stringify(stats, null, 2));

    console.log('\n=== Adoption Statistics ===');
    console.log(`Total scanned: ${stats.total_scanned}`);
    console.log(`\nAdoption Rates:`);
    console.log(`  Accessibility Header: ${stats.adoption.accessibility_header.percentage}%`);
    console.log(`  .well-known endpoint: ${stats.adoption.well_known_endpoint.percentage}%`);
    console.log(`  WCAG AA compliant: ${stats.adoption.wcag_aa_compliant.percentage}%`);
    console.log(`  WCAG AAA compliant: ${stats.adoption.wcag_aaa_compliant.percentage}%`);
    console.log(`\nScore Statistics:`);
    console.log(`  Average: ${stats.scores.average}`);
    console.log(`  Median: ${stats.scores.median}`);
    console.log(`  Range: ${stats.scores.min} - ${stats.scores.max}`);

    return stats;
  }
}

// CLI usage
if (require.main === module) {
  const limit = parseInt(process.argv[2]) || 100;

  const tracker = new AccessibilityAdoptionTracker({
    topSitesFile: process.argv[3] || 'top-1m.csv',
    outputFile: 'adoption-data.json',
    concurrency: 5
  });

  tracker.run(limit)
    .then(() => {
      console.log('\nScan complete!');
      process.exit(0);
    })
    .catch(error => {
      console.error('Error:', error);
      process.exit(1);
    });
}

module.exports = AccessibilityAdoptionTracker;
