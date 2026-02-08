/**
 * Accessibility Everywhere - Popup Script
 * Displays accessibility score and details
 */

(async function() {
  'use strict';

  const content = document.getElementById('content');

  // Get current tab
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

  if (!tab || !tab.url || (!tab.url.startsWith('https://') && !tab.url.startsWith('https://'))) {
    showError('This page cannot be scanned. Accessibility Everywhere only works on regular web pages.');
    return;
  }

  try {
    // Get score from background script
    const response = await chrome.runtime.sendMessage({
      action: 'getScore',
      url: tab.url
    });

    if (response.success && response.data) {
      displayResults(response.data, tab.url);
    } else {
      // Trigger new scan
      await performScan(tab.url);
    }
  } catch (error) {
    console.error('Error loading score:', error);
    showError('Unable to load accessibility score. Please try again.');
  }

  /**
   * Perform new scan
   */
  async function performScan(url) {
    try {
      const response = await chrome.runtime.sendMessage({
        action: 'scanPage',
        url: url
      });

      if (response.success) {
        displayResults(response.data, url);
      } else {
        showError('Scan failed: ' + (response.error || 'Unknown error'));
      }
    } catch (error) {
      showError('Unable to scan page: ' + error.message);
    }
  }

  /**
   * Display scan results
   */
  function displayResults(data, url) {
    const score = data.overall || 0;
    const scoreLevel = getScoreLevel(score);

    const issuesHtml = data.issues && data.issues.length > 0
      ? data.issues.map(issue => `
          <div class="issue-item issue-${issue.severity}">
            <div class="issue-header">
              <span class="issue-title">${issue.description}</span>
              ${issue.count ? `<span class="issue-count">${issue.count}</span>` : ''}
            </div>
            ${issue.wcag ? `<div class="issue-wcag">WCAG ${issue.wcag}</div>` : ''}
          </div>
        `).join('')
      : '<p style="text-align: center; color: #6b7280; font-size: 13px;">No issues detected!</p>';

    content.innerHTML = `
      <div class="score-container">
        <div class="score-circle score-${scoreLevel.class}">
          ${score}
        </div>
        <div class="score-label score-${scoreLevel.class}">${scoreLevel.label}</div>
        <div class="score-description">${scoreLevel.description}</div>

        <div class="wcag-badges">
          <div class="wcag-badge ${data.wcag?.a ? 'pass' : 'fail'}">
            WCAG A ${data.wcag?.a ? '✓' : '✗'}
          </div>
          <div class="wcag-badge ${data.wcag?.aa ? 'pass' : 'fail'}">
            WCAG AA ${data.wcag?.aa ? '✓' : '✗'}
          </div>
          <div class="wcag-badge ${data.wcag?.aaa ? 'pass' : 'fail'}">
            WCAG AAA ${data.wcag?.aaa ? '✓' : '✗'}
          </div>
        </div>
      </div>

      ${data.issues && data.issues.length > 0 ? `
        <div class="issues-section">
          <div class="section-title">
            <span>🔍 Issues Found</span>
          </div>
          ${issuesHtml}
        </div>
      ` : ''}

      <div class="actions">
        <button class="btn btn-primary" id="rescan">
          🔄 Re-scan Page
        </button>
        <button class="btn btn-secondary" id="report">
          📝 Report Issue
        </button>
        <button class="btn btn-secondary" id="viewFull">
          📊 View Full Report
        </button>
      </div>

      <div class="footer">
        <p>Last scanned: ${new Date(data.timestamp).toLocaleTimeString()}</p>
        <p><a href="https://accessibility-everywhere.org" target="_blank">Learn More</a> •
           <a href="#" id="options">Settings</a></p>
      </div>
    `;

    // Add event listeners
    document.getElementById('rescan')?.addEventListener('click', () => {
      content.innerHTML = '<div class="loading"><div class="spinner"></div><p>Re-scanning...</p></div>';
      performScan(url);
    });

    document.getElementById('report')?.addEventListener('click', () => {
      showReportDialog(url, data);
    });

    document.getElementById('viewFull')?.addEventListener('click', () => {
      chrome.tabs.create({
        url: `https://accessibility-everywhere.org/report?url=${encodeURIComponent(url)}`
      });
    });

    document.getElementById('options')?.addEventListener('click', (e) => {
      e.preventDefault();
      chrome.runtime.openOptionsPage();
    });
  }

  /**
   * Show error message
   */
  function showError(message) {
    content.innerHTML = `
      <div class="error">
        <strong>Error:</strong> ${message}
      </div>
      <div class="actions">
        <button class="btn btn-secondary" id="retry">
          🔄 Try Again
        </button>
      </div>
    `;

    document.getElementById('retry')?.addEventListener('click', () => {
      window.location.reload();
    });
  }

  /**
   * Show report dialog
   */
  function showReportDialog(url, data) {
    content.innerHTML = `
      <div class="issues-section">
        <div class="section-title">📝 Report Accessibility Issue</div>
        <form id="reportForm" style="margin-top: 16px;">
          <div style="margin-bottom: 12px;">
            <label for="issueType" style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 4px;">
              Issue Type
            </label>
            <select id="issueType" style="width: 100%; padding: 8px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 13px;">
              <option value="keyboard">Keyboard Navigation</option>
              <option value="screenreader">Screen Reader</option>
              <option value="contrast">Color Contrast</option>
              <option value="forms">Form Labels</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div style="margin-bottom: 12px;">
            <label for="description" style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 4px;">
              Description
            </label>
            <textarea id="description" rows="4"
              style="width: 100%; padding: 8px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 13px; font-family: inherit;"
              placeholder="Describe the accessibility issue you encountered..."
              required></textarea>
          </div>
          <div style="display: flex; gap: 8px;">
            <button type="submit" class="btn btn-primary" style="flex: 1;">
              Submit Report
            </button>
            <button type="button" class="btn btn-secondary" id="cancel" style="flex: 1;">
              Cancel
            </button>
          </div>
        </form>
      </div>
    `;

    document.getElementById('reportForm')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const issueType = document.getElementById('issueType').value;
      const description = document.getElementById('description').value;

      try {
        await chrome.runtime.sendMessage({
          action: 'reportIssue',
          data: {
            url,
            issueType,
            description,
            score: data.overall,
            userAgent: navigator.userAgent
          }
        });

        content.innerHTML = `
          <div class="score-container">
            <div style="font-size: 48px; margin-bottom: 16px;">✅</div>
            <div class="score-label">Thank You!</div>
            <div class="score-description" style="margin-top: 12px;">
              Your report helps make the web more accessible.
            </div>
          </div>
          <div class="actions">
            <button class="btn btn-primary" id="back">
              ← Back to Results
            </button>
          </div>
        `;

        document.getElementById('back')?.addEventListener('click', () => {
          displayResults(data, url);
        });
      } catch (error) {
        alert('Failed to submit report. Please try again.');
      }
    });

    document.getElementById('cancel')?.addEventListener('click', () => {
      displayResults(data, url);
    });
  }

  /**
   * Get score level information
   */
  function getScoreLevel(score) {
    if (score >= 90) {
      return {
        class: 'excellent',
        label: 'Excellent',
        description: 'This site has excellent accessibility'
      };
    } else if (score >= 75) {
      return {
        class: 'good',
        label: 'Good',
        description: 'This site has good accessibility with minor issues'
      };
    } else if (score >= 60) {
      return {
        class: 'fair',
        label: 'Fair',
        description: 'This site has some accessibility issues'
      };
    } else if (score >= 40) {
      return {
        class: 'poor',
        label: 'Poor',
        description: 'This site has significant accessibility problems'
      };
    } else {
      return {
        class: 'critical',
        label: 'Critical',
        description: 'This site has critical accessibility barriers'
      };
    }
  }
})();
