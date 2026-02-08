/**
 * Accessibility Test GitHub Action
 * Tests websites for WCAG compliance in CI/CD
 */

const core = require('@actions/core');
const github = require('@actions/github');
const { chromium } = require('playwright');
const { AxePuppeteer } = require('@axe-core/puppeteer');

async function run() {
  try {
    // Get inputs
    const url = core.getInput('url');
    const minScore = parseInt(core.getInput('min-score'));
    const wcagLevel = core.getInput('wcag-level');
    const failOnRegression = core.getInput('fail-on-regression') === 'true';
    const reportPrComment = core.getInput('report-pr-comment') === 'true';
    const githubToken = core.getInput('github-token');

    if (!url) {
      core.setFailed('URL is required');
      return;
    }

    core.info(`Testing accessibility for: ${url}`);
    core.info(`Minimum score: ${minScore}`);
    core.info(`WCAG level: ${wcagLevel}`);

    // Run accessibility scan
    const results = await runAccessibilityScan(url, wcagLevel);

    // Calculate score
    const score = calculateScore(results);

    // Check compliance
    const compliant = checkWCAGCompliance(results, wcagLevel);

    // Set outputs
    core.setOutput('score', score);
    core.setOutput('wcag-compliant', compliant);
    core.setOutput('passed', score >= minScore && compliant);

    // Generate report
    const report = generateReport(results, score, compliant, url);

    // Post PR comment if enabled
    if (reportPrComment && githubToken && github.context.payload.pull_request) {
      await postPRComment(githubToken, report, score, minScore);
    }

    // Log results
    core.info(`\n${report}`);

    // Determine pass/fail
    if (score < minScore) {
      core.setFailed(`Accessibility score ${score} is below minimum ${minScore}`);
    } else if (!compliant) {
      core.setFailed(`Site does not meet WCAG ${wcagLevel} compliance`);
    } else {
      core.info(`✅ Accessibility test passed! Score: ${score}/100`);
    }

  } catch (error) {
    core.setFailed(`Action failed: ${error.message}`);
  }
}

async function runAccessibilityScan(url, wcagLevel) {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    await page.goto(url, { waitUntil: 'networkidle' });

    // Run axe-core
    const axe = new AxePuppeteer(page);
    const results = await axe
      .withTags([`wcag2${wcagLevel.toLowerCase()}`])
      .analyze();

    await browser.close();

    return results;
  } catch (error) {
    await browser.close();
    throw error;
  }
}

function calculateScore(results) {
  const violations = results.violations || [];

  let score = 100;

  violations.forEach(violation => {
    const impact = violation.impact;
    const count = violation.nodes.length;

    // Deduct points based on severity and count
    const deduction = {
      critical: 10,
      serious: 5,
      moderate: 2,
      minor: 1
    }[impact] || 1;

    score -= (deduction * count);
  });

  return Math.max(0, Math.min(100, score));
}

function checkWCAGCompliance(results, level) {
  const violations = results.violations || [];

  // Check if there are any violations for the specified WCAG level
  const criticalViolations = violations.filter(v =>
    v.impact === 'critical' || v.impact === 'serious'
  );

  return criticalViolations.length === 0;
}

function generateReport(results, score, compliant, url) {
  const violations = results.violations || [];

  let report = `
# Accessibility Test Results

**URL:** ${url}
**Score:** ${score}/100
**WCAG Compliant:** ${compliant ? '✅ Yes' : '❌ No'}

## Summary

- **Total Issues:** ${violations.reduce((sum, v) => sum + v.nodes.length, 0)}
- **Critical:** ${violations.filter(v => v.impact === 'critical').reduce((sum, v) => sum + v.nodes.length, 0)}
- **Serious:** ${violations.filter(v => v.impact === 'serious').reduce((sum, v) => sum + v.nodes.length, 0)}
- **Moderate:** ${violations.filter(v => v.impact === 'moderate').reduce((sum, v) => sum + v.nodes.length, 0)}
- **Minor:** ${violations.filter(v => v.impact === 'minor').reduce((sum, v) => sum + v.nodes.length, 0)}

`;

  if (violations.length > 0) {
    report += '## Issues Found\n\n';

    violations.forEach(violation => {
      const count = violation.nodes.length;
      const impact = violation.impact;
      const emoji = {
        critical: '🔴',
        serious: '🟠',
        moderate: '🟡',
        minor: '⚪'
      }[impact] || '⚪';

      report += `### ${emoji} ${violation.help}\n\n`;
      report += `**Impact:** ${impact}\n`;
      report += `**WCAG:** ${violation.tags.filter(t => t.startsWith('wcag')).join(', ')}\n`;
      report += `**Count:** ${count} instance${count > 1 ? 's' : ''}\n`;
      report += `**Description:** ${violation.description}\n`;
      report += `**Fix:** ${violation.helpUrl}\n\n`;
    });
  } else {
    report += '## 🎉 No Issues Found!\n\n';
    report += 'This page appears to meet all accessibility requirements.\n';
  }

  return report;
}

async function postPRComment(token, report, score, minScore) {
  const octokit = github.getOctokit(token);
  const context = github.context;

  const emoji = score >= minScore ? '✅' : '❌';
  const status = score >= minScore ? 'PASSED' : 'FAILED';

  const comment = `
## ${emoji} Accessibility Test ${status}

${report}

---
*Automated accessibility testing by [Accessibility Everywhere](https://accessibility-everywhere.org)*
  `.trim();

  await octokit.rest.issues.createComment({
    ...context.repo,
    issue_number: context.payload.pull_request.number,
    body: comment
  });
}

run();

module.exports = { run };
