/**
 * Accessibility Everywhere - Content Script
 * Runs on every page to enable scanning and reporting
 */

(async function() {
  'use strict';

  // Check if extension should run on this page
  if (window.location.protocol !== 'http:' && window.location.protocol !== 'https:') {
    return;
  }

  // Prevent multiple injections
  if (window.accessibilityEverywhereInjected) {
    return;
  }
  window.accessibilityEverywhereInjected = true;

  /**
   * Inject accessibility scanner library (axe-core)
   * In production, this would inject axe-core or similar
   */
  function injectScanner() {
    return new Promise((resolve, reject) => {
      // In MVP, we'll use a lightweight local scanner
      // In production, inject axe-core from web_accessible_resources
      const script = document.createElement('script');
      script.src = chrome.runtime.getURL('scanner.js');
      script.onload = resolve;
      script.onerror = reject;
      (document.head || document.documentElement).appendChild(script);
    });
  }

  /**
   * Perform local accessibility scan
   */
  async function performLocalScan() {
    // Wait for scanner to be injected
    if (typeof window.runAccessibilityScan === 'function') {
      return await window.runAccessibilityScan();
    }

    // Fallback: basic manual checks
    return performBasicChecks();
  }

  /**
   * Basic accessibility checks without external library
   */
  function performBasicChecks() {
    const issues = [];
    let score = 100;

    // Check 1: Images without alt text
    const imagesWithoutAlt = document.querySelectorAll('img:not([alt])');
    if (imagesWithoutAlt.length > 0) {
      issues.push({
        type: 'missing-alt',
        severity: 'serious',
        wcag: '1.1.1',
        count: imagesWithoutAlt.length,
        description: `${imagesWithoutAlt.length} images missing alt text`,
        elements: Array.from(imagesWithoutAlt).slice(0, 5).map(el => el.outerHTML.substring(0, 100))
      });
      score -= Math.min(20, imagesWithoutAlt.length * 2);
    }

    // Check 2: Links without text
    const linksWithoutText = Array.from(document.querySelectorAll('a')).filter(a => {
      const text = a.textContent.trim();
      const ariaLabel = a.getAttribute('aria-label');
      const ariaLabelledBy = a.getAttribute('aria-labelledby');
      return !text && !ariaLabel && !ariaLabelledBy;
    });
    if (linksWithoutText.length > 0) {
      issues.push({
        type: 'empty-link',
        severity: 'serious',
        wcag: '2.4.4',
        count: linksWithoutText.length,
        description: `${linksWithoutText.length} links without descriptive text`
      });
      score -= Math.min(15, linksWithoutText.length * 3);
    }

    // Check 3: Form inputs without labels
    const inputsWithoutLabels = Array.from(document.querySelectorAll('input[type]:not([type="hidden"]):not([type="submit"]):not([type="button"])')).filter(input => {
      const id = input.id;
      const ariaLabel = input.getAttribute('aria-label');
      const ariaLabelledBy = input.getAttribute('aria-labelledby');
      const hasLabel = id && document.querySelector(`label[for="${id}"]`);
      return !hasLabel && !ariaLabel && !ariaLabelledBy;
    });
    if (inputsWithoutLabels.length > 0) {
      issues.push({
        type: 'unlabeled-input',
        severity: 'critical',
        wcag: '3.3.2',
        count: inputsWithoutLabels.length,
        description: `${inputsWithoutLabels.length} form inputs without labels`
      });
      score -= Math.min(25, inputsWithoutLabels.length * 5);
    }

    // Check 4: Missing language attribute
    const htmlLang = document.documentElement.getAttribute('lang');
    if (!htmlLang) {
      issues.push({
        type: 'missing-lang',
        severity: 'serious',
        wcag: '3.1.1',
        count: 1,
        description: 'Page missing language attribute'
      });
      score -= 10;
    }

    // Check 5: Headings structure
    const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
    const h1Count = document.querySelectorAll('h1').length;
    if (h1Count === 0) {
      issues.push({
        type: 'missing-h1',
        severity: 'moderate',
        wcag: '2.4.6',
        count: 1,
        description: 'Page missing main heading (h1)'
      });
      score -= 5;
    } else if (h1Count > 1) {
      issues.push({
        type: 'multiple-h1',
        severity: 'minor',
        wcag: '2.4.6',
        count: h1Count,
        description: `Multiple h1 headings found (${h1Count})`
      });
      score -= 3;
    }

    // Check 6: Skip links
    const skipLink = document.querySelector('a[href^="#"]');
    const hasSkipToMain = Array.from(document.querySelectorAll('a[href^="#"]')).some(a =>
      a.textContent.toLowerCase().includes('skip') ||
      a.textContent.toLowerCase().includes('main')
    );
    if (!hasSkipToMain) {
      issues.push({
        type: 'missing-skip-link',
        severity: 'moderate',
        wcag: '2.4.1',
        count: 1,
        description: 'No skip navigation link found'
      });
      score -= 5;
    }

    // Check 7: Color contrast (basic check for inline styles only)
    // Note: Full color contrast checking requires computed styles and is complex
    const lowContrastWarning = {
      type: 'contrast-check-needed',
      severity: 'moderate',
      wcag: '1.4.3',
      count: 1,
      description: 'Comprehensive color contrast check recommended (use full scan)'
    };

    // Ensure score doesn't go below 0
    score = Math.max(0, score);

    return {
      overall: score,
      issues,
      timestamp: Date.now(),
      scanType: 'local-basic',
      wcag: {
        a: score >= 75,
        aa: score >= 85,
        aaa: score >= 95
      }
    };
  }

  /**
   * Listen for scan requests
   */
  chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.action === 'scanCurrentPage') {
      performLocalScan()
        .then(result => sendResponse({ success: true, data: result }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
    }
  });

  // Auto-scan on page load if enabled
  chrome.storage.sync.get(['autoScan'], (result) => {
    if (result.autoScan !== false) {
      // Notify background script to scan this page
      chrome.runtime.sendMessage({
        action: 'scanPage',
        url: window.location.href
      });
    }
  });

  /**
   * Developer mode: Inject accessibility hints
   */
  chrome.storage.sync.get(['devMode'], (result) => {
    if (result.devMode) {
      injectDevModeOverlay();
    }
  });

  /**
   * Inject developer mode overlay showing accessibility issues
   */
  function injectDevModeOverlay() {
    const style = document.createElement('style');
    style.textContent = `
      .a11y-error {
        outline: 3px solid #ef4444 !important;
        outline-offset: 2px !important;
      }
      .a11y-warning {
        outline: 3px solid #f59e0b !important;
        outline-offset: 2px !important;
      }
      .a11y-tooltip {
        position: absolute;
        background: #1f2937;
        color: white;
        padding: 8px 12px;
        border-radius: 6px;
        font-size: 12px;
        font-family: system-ui, -apple-system, sans-serif;
        z-index: 999999;
        pointer-events: none;
        max-width: 300px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
      }
    `;
    document.head.appendChild(style);

    // Highlight problematic elements
    performBasicChecks().then(result => {
      result.issues.forEach(issue => {
        // This is simplified; in production would need selectors for each issue
        console.log(`[Accessibility Everywhere Dev Mode] ${issue.description}`);
      });
    });
  }

  // Listen for storage changes (e.g., dev mode toggled)
  chrome.storage.onChanged.addListener((changes, namespace) => {
    if (changes.devMode && changes.devMode.newValue) {
      injectDevModeOverlay();
    }
  });

})();
