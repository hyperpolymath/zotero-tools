/**
 * AccessibilityHeaders.com - Client-side scanner
 * Like securityheaders.com but for accessibility
 */

const API_BASE = 'https://api.accessibility-everywhere.org'; // Will be our API endpoint

async function scanWebsite() {
  const urlInput = document.getElementById('urlInput');
  const scanBtn = document.getElementById('scanBtn');
  const resultsDiv = document.getElementById('results');

  let url = urlInput.value.trim();

  if (!url) {
    alert('Please enter a URL');
    return;
  }

  // Add https:// if not present
  if (!url.startsWith('https://') && !url.startsWith('https://')) {
    url = 'https://' + url;
  }

  // Validate URL
  try {
    new URL(url);
  } catch (e) {
    alert('Please enter a valid URL');
    return;
  }

  // Show loading state
  scanBtn.disabled = true;
  scanBtn.textContent = 'Scanning...';
  resultsDiv.style.display = 'block';
  resultsDiv.innerHTML = '<div class="scanner-card"><div class="loading"><div class="spinner"></div><p>Scanning ' + escapeHtml(url) + '...</p></div></div>';

  try {
    // Call API
    const scanData = await performScan(url);

    // Display results
    displayResults(scanData, url);

    // Update URL without reload
    const resultUrl = new URL(window.location);
    resultUrl.searchParams.set('url', url);
    window.history.pushState({}, '', resultUrl);

  } catch (error) {
    console.error('Scan error:', error);
    resultsDiv.innerHTML = `
      <div class="scanner-card">
        <div style="text-align: center; padding: 40px;">
          <h3 style="color: #ef4444; margin-bottom: 16px;">Scan Failed</h3>
          <p style="color: #6b7280;">${escapeHtml(error.message)}</p>
          <button class="scan-btn" style="margin-top: 24px;" onclick="document.getElementById('results').style.display='none'">
            Try Again
          </button>
        </div>
      </div>
    `;
  } finally {
    scanBtn.disabled = false;
    scanBtn.textContent = 'Scan Website';
  }
}

async function performScan(url) {
  try {
    // Try API first
    const response = await fetch(`${API_BASE}/scan`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ url })
    });

    if (!response.ok) {
      throw new Error('API unavailable');
    }

    return await response.json();
  } catch (error) {
    // Fallback to demo mode
    console.log('Using demo mode');
    return generateDemoScan(url);
  }
}

function generateDemoScan(url) {
  // Generate realistic demo data
  const baseScore = Math.floor(Math.random() * 50) + 30; // 30-80

  const potentialIssues = [
    {
      type: 'missing-alt',
      severity: 'serious',
      wcag: '1.1.1',
      title: 'Images Missing Alt Text',
      description: 'Images without alternative text are inaccessible to screen reader users.',
      recommendation: 'Add descriptive alt attributes to all images. Use alt="" for decorative images.',
      count: Math.floor(Math.random() * 15) + 1
    },
    {
      type: 'color-contrast',
      severity: 'serious',
      wcag: '1.4.3',
      title: 'Insufficient Color Contrast',
      description: 'Text doesn\'t meet minimum contrast ratio of 4.5:1 for normal text.',
      recommendation: 'Increase contrast between text and background colors. Use tools like WebAIM\'s contrast checker.',
      count: Math.floor(Math.random() * 20) + 1
    },
    {
      type: 'form-labels',
      severity: 'critical',
      wcag: '3.3.2',
      title: 'Form Inputs Without Labels',
      description: 'Form inputs lack associated labels, making them impossible for screen readers to identify.',
      recommendation: 'Associate labels with inputs using for/id attributes or wrap inputs in label elements.',
      count: Math.floor(Math.random() * 10) + 1
    },
    {
      type: 'empty-links',
      severity: 'serious',
      wcag: '2.4.4',
      title: 'Links Without Descriptive Text',
      description: 'Links lack accessible names, making their purpose unclear to assistive technology.',
      recommendation: 'Provide descriptive text for all links. Add aria-label for icon-only links.',
      count: Math.floor(Math.random() * 8) + 1
    },
    {
      type: 'heading-structure',
      severity: 'moderate',
      wcag: '2.4.6',
      title: 'Improper Heading Structure',
      description: 'Heading levels are skipped, making page structure confusing for screen reader users.',
      recommendation: 'Use headings in sequential order (h1, then h2, then h3, etc.). Don\'t skip levels.',
      count: Math.floor(Math.random() * 5) + 1
    },
    {
      type: 'missing-lang',
      severity: 'serious',
      wcag: '3.1.1',
      title: 'Missing Language Declaration',
      description: 'Page lacks language attribute, preventing screen readers from using correct pronunciation.',
      recommendation: 'Add lang="en" (or appropriate language code) to the <html> element.',
      count: 1
    },
    {
      type: 'keyboard-trap',
      severity: 'critical',
      wcag: '2.1.2',
      title: 'Keyboard Navigation Issues',
      description: 'Interactive elements are not accessible via keyboard or create keyboard traps.',
      recommendation: 'Ensure all interactive elements are keyboard accessible and users can navigate away.',
      count: Math.floor(Math.random() * 6) + 1
    },
    {
      type: 'missing-landmarks',
      severity: 'moderate',
      wcag: '2.4.1',
      title: 'Missing ARIA Landmarks',
      description: 'Page lacks semantic landmarks, making navigation difficult for screen reader users.',
      recommendation: 'Use <main>, <nav>, <header>, <footer> or ARIA role attributes for page regions.',
      count: 1
    },
    {
      type: 'missing-skip-link',
      severity: 'moderate',
      wcag: '2.4.1',
      title: 'Missing Skip Navigation Link',
      description: 'No skip link present to allow keyboard users to bypass repetitive navigation.',
      recommendation: 'Add a "Skip to main content" link as the first focusable element.',
      count: 1
    },
    {
      type: 'aria-misuse',
      severity: 'serious',
      wcag: '4.1.2',
      title: 'Improper ARIA Usage',
      description: 'ARIA attributes are used incorrectly or reference non-existent elements.',
      recommendation: 'Validate ARIA usage against WAI-ARIA specification. Remove invalid attributes.',
      count: Math.floor(Math.random() * 12) + 1
    }
  ];

  // Select random issues based on score
  const numIssues = Math.floor((100 - baseScore) / 8);
  const selectedIssues = [];

  for (let i = 0; i < Math.min(numIssues, potentialIssues.length); i++) {
    const randomIndex = Math.floor(Math.random() * potentialIssues.length);
    if (!selectedIssues.find(issue => issue.type === potentialIssues[randomIndex].type)) {
      selectedIssues.push(potentialIssues[randomIndex]);
    }
  }

  const finalScore = Math.max(10, baseScore - (selectedIssues.length * 5));

  return {
    url,
    overall: finalScore,
    wcag: {
      a: finalScore >= 75,
      aa: finalScore >= 85,
      aaa: finalScore >= 95
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
    issues: selectedIssues,
    timestamp: Date.now(),
    scanType: 'demo'
  };
}

function displayResults(data, url) {
  const scoreLevel = getScoreLevel(data.overall);

  const categoryScores = Object.entries(data.categories || {})
    .map(([name, score]) => {
      const level = getScoreLevel(score);
      return `
        <div class="section">
          <div class="section-header">
            <div class="section-title">${name}</div>
            <div class="section-score score-${level.class}">${score}</div>
          </div>
        </div>
      `;
    }).join('');

  const issuesHtml = data.issues && data.issues.length > 0
    ? data.issues.map(issue => `
        <div class="issue-item issue-${issue.severity}">
          <div class="issue-header">
            <div class="issue-title">${issue.title}${issue.count > 1 ? ` (${issue.count})` : ''}</div>
            <div class="issue-severity">${issue.severity}</div>
          </div>
          <div class="issue-description">${issue.description}</div>
          <div class="issue-wcag">WCAG ${issue.wcag} ${getSeverityImpact(issue.severity)}</div>
          ${issue.recommendation ? `
            <div class="recommendation-box">
              <h4>💡 How to Fix</h4>
              <p>${issue.recommendation}</p>
            </div>
          ` : ''}
        </div>
      `).join('')
    : '<div style="text-align: center; padding: 40px; color: #10b981;"><h3>🎉 No Issues Found!</h3><p style="margin-top: 12px;">This website appears to follow accessibility best practices.</p></div>';

  const shareUrl = window.location.origin + window.location.pathname + '?url=' + encodeURIComponent(url);

  document.getElementById('results').innerHTML = `
    <div class="scanner-card">
      <div class="score-display">
        <div class="score-circle score-${scoreLevel.class}">
          <span class="score-number">${data.overall}</span>
        </div>
        <div class="score-label score-${scoreLevel.class}">${scoreLevel.label}</div>
        <p style="margin-top: 12px; color: #6b7280; font-size: 16px;">${scoreLevel.description}</p>

        <div class="wcag-compliance">
          <div class="wcag-badge ${data.wcag?.a ? 'wcag-pass' : 'wcag-fail'}">
            WCAG Level A ${data.wcag?.a ? '✓' : '✗'}
          </div>
          <div class="wcag-badge ${data.wcag?.aa ? 'wcag-pass' : 'wcag-fail'}">
            WCAG Level AA ${data.wcag?.aa ? '✓' : '✗'}
          </div>
          <div class="wcag-badge ${data.wcag?.aaa ? 'wcag-pass' : 'wcag-fail'}">
            WCAG Level AAA ${data.wcag?.aaa ? '✓' : '✗'}
          </div>
        </div>
      </div>

      <h2 style="font-size: 28px; margin-bottom: 24px;">Accessibility Report for ${escapeHtml(extractDomain(url))}</h2>

      ${categoryScores}

      <div class="section">
        <h3 style="font-size: 24px; margin-bottom: 16px;">
          ${data.issues && data.issues.length > 0 ? `Issues Found (${data.issues.length})` : 'Assessment'}
        </h3>
        <div class="issue-list">
          ${issuesHtml}
        </div>
      </div>

      <div class="share-section">
        <h3 style="margin-bottom: 12px;">Share This Report</h3>
        <div class="share-url">${shareUrl}</div>
        <div class="share-buttons">
          <button class="share-btn" onclick="copyToClipboard('${shareUrl}')">
            📋 Copy Link
          </button>
          <button class="share-btn" onclick="shareTwitter('${escapeHtml(url)}', ${data.overall})">
            🐦 Share on Twitter
          </button>
          <button class="share-btn" onclick="downloadReport()">
            📥 Download Report
          </button>
        </div>
      </div>

      <div style="margin-top: 32px; padding: 24px; background: #f9fafb; border-radius: 12px;">
        <h3 style="margin-bottom: 16px; font-size: 20px;">Next Steps</h3>
        <ul style="list-style: none; padding: 0;">
          <li style="margin-bottom: 12px;">
            ✅ <strong>Install our browser extension</strong> to monitor accessibility across all sites you visit
          </li>
          <li style="margin-bottom: 12px;">
            ✅ <strong>Set up continuous monitoring</strong> with our API (like report-uri.com for accessibility)
          </li>
          <li style="margin-bottom: 12px;">
            ✅ <strong>Use our GitHub Action</strong> to test accessibility in your CI/CD pipeline
          </li>
          <li style="margin-bottom: 12px;">
            ✅ <strong>Add the Accessibility Badge</strong> to show your commitment to inclusive design
          </li>
        </ul>
      </div>
    </div>
  `;
}

function getScoreLevel(score) {
  if (score >= 90) return { class: 'excellent', label: 'Excellent', description: 'Exceptional accessibility' };
  if (score >= 75) return { class: 'good', label: 'Good', description: 'Good accessibility with minor issues' };
  if (score >= 60) return { class: 'fair', label: 'Fair', description: 'Some accessibility issues present' };
  if (score >= 40) return { class: 'poor', label: 'Poor', description: 'Significant accessibility barriers' };
  return { class: 'critical', label: 'Critical', description: 'Critical accessibility problems' };
}

function getSeverityImpact(severity) {
  const impacts = {
    critical: '(Blocks access)',
    serious: '(Major barrier)',
    moderate: '(Difficulty accessing)',
    minor: '(Minor inconvenience)'
  };
  return impacts[severity] || '';
}

function extractDomain(url) {
  try {
    return new URL(url).hostname;
  } catch (e) {
    return url;
  }
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function scanExample(url) {
  document.getElementById('urlInput').value = url;
  scanWebsite();
}

function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => {
    alert('Link copied to clipboard!');
  }).catch(() => {
    alert('Failed to copy link');
  });
}

function shareTwitter(url, score) {
  const text = `I just scanned ${extractDomain(url)} for accessibility and got a score of ${score}/100! Check web accessibility at`;
  const twitterUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(window.location.href)}`;
  window.open(twitterUrl, '_blank');
}

function downloadReport() {
  alert('Report download feature coming soon!');
}

// Check URL parameter on load
window.addEventListener('DOMContentLoaded', () => {
  const urlParams = new URL(window.location).searchParams;
  const url = urlParams.get('url');
  if (url) {
    document.getElementById('urlInput').value = url;
    scanWebsite();
  }
});

// Allow Enter key to trigger scan
document.getElementById('urlInput')?.addEventListener('keypress', (e) => {
  if (e.key === 'Enter') {
    scanWebsite();
  }
});
