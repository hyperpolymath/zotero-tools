/**
 * Accessibility Everywhere - Scanner Module
 * Injected into pages to perform local accessibility testing
 * This is a lightweight implementation - in production would use axe-core
 */

(function() {
  'use strict';

  // Prevent double injection
  if (window.runAccessibilityScan) {
    return;
  }

  /**
   * Main scan function - exposed to content script
   */
  window.runAccessibilityScan = async function() {
    const startTime = Date.now();
    const issues = [];
    let score = 100;

    // Run all checks
    const checks = [
      checkImages,
      checkLinks,
      checkFormLabels,
      checkHeadings,
      checkLandmarks,
      checkLanguage,
      checkColorContrast,
      checkARIA,
      checkKeyboardAccessibility,
      checkMediaAlternatives
    ];

    for (const check of checks) {
      try {
        const result = await check();
        if (result.issues.length > 0) {
          issues.push(...result.issues);
          score -= result.penalty;
        }
      } catch (error) {
        console.error('Check failed:', error);
      }
    }

    // Ensure score is between 0-100
    score = Math.max(0, Math.min(100, score));

    // Calculate WCAG compliance
    const wcagCompliance = {
      a: score >= 75,
      aa: score >= 85,
      aaa: score >= 95
    };

    const scanTime = Date.now() - startTime;

    return {
      overall: Math.round(score),
      wcag: wcagCompliance,
      issues: issues.sort((a, b) => {
        const severityOrder = { critical: 0, serious: 1, moderate: 2, minor: 3 };
        return severityOrder[a.severity] - severityOrder[b.severity];
      }),
      timestamp: Date.now(),
      scanTime,
      scanType: 'local-comprehensive'
    };
  };

  /**
   * Check images for alt text
   */
  function checkImages() {
    const images = document.querySelectorAll('img');
    const issues = [];
    let penalty = 0;

    images.forEach(img => {
      const alt = img.getAttribute('alt');
      const ariaLabel = img.getAttribute('aria-label');
      const ariaLabelledby = img.getAttribute('aria-labelledby');
      const role = img.getAttribute('role');

      // Image is decorative if role="presentation" or alt=""
      if (role === 'presentation' || role === 'none' || alt === '') {
        return;
      }

      // Image needs alternative text
      if (alt === null && !ariaLabel && !ariaLabelledby) {
        issues.push({
          type: 'missing-alt',
          severity: 'serious',
          wcag: '1.1.1',
          description: 'Image missing alternative text',
          element: getElementSelector(img)
        });
        penalty += 2;
      }
    });

    return { issues, penalty: Math.min(penalty, 20) };
  }

  /**
   * Check links for accessible text
   */
  function checkLinks() {
    const links = document.querySelectorAll('a[href]');
    const issues = [];
    let penalty = 0;

    links.forEach(link => {
      const text = link.textContent.trim();
      const ariaLabel = link.getAttribute('aria-label');
      const ariaLabelledby = link.getAttribute('aria-labelledby');
      const title = link.getAttribute('title');

      // Link must have accessible text
      if (!text && !ariaLabel && !ariaLabelledby && !title) {
        issues.push({
          type: 'empty-link',
          severity: 'serious',
          wcag: '2.4.4',
          description: 'Link has no accessible text',
          element: getElementSelector(link)
        });
        penalty += 3;
      }

      // Check for vague link text
      const vagueText = ['click here', 'read more', 'more', 'here', 'link'];
      if (vagueText.includes(text.toLowerCase())) {
        issues.push({
          type: 'vague-link-text',
          severity: 'moderate',
          wcag: '2.4.4',
          description: `Link text "${text}" is not descriptive`,
          element: getElementSelector(link)
        });
        penalty += 1;
      }
    });

    return { issues, penalty: Math.min(penalty, 15) };
  }

  /**
   * Check form inputs for labels
   */
  function checkFormLabels() {
    const inputs = document.querySelectorAll('input:not([type="hidden"]):not([type="submit"]):not([type="button"]):not([type="reset"]), textarea, select');
    const issues = [];
    let penalty = 0;

    inputs.forEach(input => {
      const id = input.id;
      const ariaLabel = input.getAttribute('aria-label');
      const ariaLabelledby = input.getAttribute('aria-labelledby');
      const hasLabel = id && document.querySelector(`label[for="${id}"]`);
      const wrappedInLabel = input.closest('label');

      if (!hasLabel && !ariaLabel && !ariaLabelledby && !wrappedInLabel) {
        issues.push({
          type: 'unlabeled-input',
          severity: 'critical',
          wcag: '3.3.2',
          description: 'Form input missing accessible label',
          element: getElementSelector(input)
        });
        penalty += 5;
      }
    });

    return { issues, penalty: Math.min(penalty, 25) };
  }

  /**
   * Check heading structure
   */
  function checkHeadings() {
    const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
    const issues = [];
    let penalty = 0;

    // Check for h1
    const h1s = document.querySelectorAll('h1');
    if (h1s.length === 0) {
      issues.push({
        type: 'missing-h1',
        severity: 'moderate',
        wcag: '2.4.6',
        description: 'Page missing main heading (h1)'
      });
      penalty += 5;
    } else if (h1s.length > 1) {
      issues.push({
        type: 'multiple-h1',
        severity: 'minor',
        wcag: '2.4.6',
        description: `Multiple h1 headings (${h1s.length} found)`,
        count: h1s.length
      });
      penalty += 2;
    }

    // Check for skipped heading levels
    let previousLevel = 0;
    headings.forEach(heading => {
      const level = parseInt(heading.tagName.substring(1));
      if (previousLevel > 0 && level > previousLevel + 1) {
        issues.push({
          type: 'skipped-heading-level',
          severity: 'moderate',
          wcag: '2.4.6',
          description: `Heading level skipped from h${previousLevel} to h${level}`,
          element: getElementSelector(heading)
        });
        penalty += 1;
      }
      previousLevel = level;
    });

    return { issues, penalty: Math.min(penalty, 10) };
  }

  /**
   * Check for ARIA landmarks and skip links
   */
  function checkLandmarks() {
    const issues = [];
    let penalty = 0;

    // Check for main landmark
    const main = document.querySelector('main, [role="main"]');
    if (!main) {
      issues.push({
        type: 'missing-main-landmark',
        severity: 'moderate',
        wcag: '2.4.1',
        description: 'Page missing main landmark'
      });
      penalty += 3;
    }

    // Check for skip link
    const skipLink = Array.from(document.querySelectorAll('a[href^="#"]')).find(a =>
      a.textContent.toLowerCase().includes('skip') ||
      a.textContent.toLowerCase().includes('main')
    );
    if (!skipLink) {
      issues.push({
        type: 'missing-skip-link',
        severity: 'moderate',
        wcag: '2.4.1',
        description: 'No skip navigation link found'
      });
      penalty += 3;
    }

    // Check for navigation landmark
    const nav = document.querySelector('nav, [role="navigation"]');
    if (!nav) {
      issues.push({
        type: 'missing-nav-landmark',
        severity: 'minor',
        wcag: '2.4.1',
        description: 'Page missing navigation landmark'
      });
      penalty += 2;
    }

    return { issues, penalty: Math.min(penalty, 8) };
  }

  /**
   * Check language attribute
   */
  function checkLanguage() {
    const issues = [];
    let penalty = 0;

    const htmlLang = document.documentElement.getAttribute('lang');
    if (!htmlLang) {
      issues.push({
        type: 'missing-lang',
        severity: 'serious',
        wcag: '3.1.1',
        description: 'Page missing language attribute'
      });
      penalty += 10;
    } else if (htmlLang.length < 2) {
      issues.push({
        type: 'invalid-lang',
        severity: 'serious',
        wcag: '3.1.1',
        description: 'Invalid language code'
      });
      penalty += 8;
    }

    return { issues, penalty };
  }

  /**
   * Check color contrast (simplified - full check requires visual analysis)
   */
  function checkColorContrast() {
    const issues = [];
    let penalty = 0;

    // This is a simplified check - real contrast checking requires:
    // 1. Computing actual text/background colors (including inheritance)
    // 2. Calculating luminance ratios
    // 3. Checking against WCAG thresholds (4.5:1 for normal text, 3:1 for large)

    // For MVP, we'll just flag this as needing deeper analysis
    const textElements = document.querySelectorAll('p, span, a, button, h1, h2, h3, h4, h5, h6, li, td, th');

    // Quick check for inline styles with potential issues
    let lowContrastCount = 0;
    textElements.forEach(el => {
      const style = window.getComputedStyle(el);
      const color = style.color;
      const bgColor = style.backgroundColor;

      // Very basic check - this is not accurate
      if (color && bgColor && color !== 'rgba(0, 0, 0, 0)' && bgColor !== 'rgba(0, 0, 0, 0)') {
        // In real implementation, calculate actual contrast ratio
        // For now, just note that contrast should be checked
      }
    });

    // Note: Real implementation would use color contrast calculation
    // For now, we add a reminder to check contrast
    if (textElements.length > 0) {
      issues.push({
        type: 'contrast-check-recommended',
        severity: 'moderate',
        wcag: '1.4.3',
        description: 'Color contrast should be verified (requires detailed analysis)',
        count: textElements.length
      });
      // Don't penalize since we can't accurately check
    }

    return { issues, penalty };
  }

  /**
   * Check ARIA usage
   */
  function checkARIA() {
    const issues = [];
    let penalty = 0;

    // Check for ARIA attributes on elements
    const ariaElements = document.querySelectorAll('[role], [aria-label], [aria-labelledby], [aria-describedby]');

    ariaElements.forEach(el => {
      const role = el.getAttribute('role');

      // Check for invalid roles (basic check)
      const validRoles = [
        'alert', 'alertdialog', 'application', 'article', 'banner', 'button',
        'cell', 'checkbox', 'columnheader', 'combobox', 'complementary',
        'contentinfo', 'dialog', 'directory', 'document', 'feed', 'figure',
        'form', 'grid', 'gridcell', 'group', 'heading', 'img', 'link', 'list',
        'listbox', 'listitem', 'main', 'marquee', 'math', 'menu', 'menubar',
        'menuitem', 'menuitemcheckbox', 'menuitemradio', 'navigation', 'none',
        'note', 'option', 'presentation', 'progressbar', 'radio', 'radiogroup',
        'region', 'row', 'rowgroup', 'rowheader', 'scrollbar', 'search',
        'searchbox', 'separator', 'slider', 'spinbutton', 'status', 'switch',
        'tab', 'table', 'tablist', 'tabpanel', 'term', 'textbox', 'timer',
        'toolbar', 'tooltip', 'tree', 'treegrid', 'treeitem'
      ];

      if (role && !validRoles.includes(role)) {
        issues.push({
          type: 'invalid-aria-role',
          severity: 'serious',
          wcag: '4.1.2',
          description: `Invalid ARIA role: ${role}`,
          element: getElementSelector(el)
        });
        penalty += 3;
      }

      // Check for aria-labelledby pointing to non-existent element
      const labelledby = el.getAttribute('aria-labelledby');
      if (labelledby && !document.getElementById(labelledby)) {
        issues.push({
          type: 'invalid-aria-labelledby',
          severity: 'serious',
          wcag: '4.1.2',
          description: `aria-labelledby references non-existent element: ${labelledby}`,
          element: getElementSelector(el)
        });
        penalty += 3;
      }
    });

    return { issues, penalty: Math.min(penalty, 15) };
  }

  /**
   * Check keyboard accessibility
   */
  function checkKeyboardAccessibility() {
    const issues = [];
    let penalty = 0;

    // Check for interactive elements without keyboard access
    const interactive = document.querySelectorAll('div[onclick], span[onclick], img[onclick]');

    interactive.forEach(el => {
      const tabindex = el.getAttribute('tabindex');
      const role = el.getAttribute('role');

      // Interactive elements need to be keyboard accessible
      if (!tabindex && !['button', 'link'].includes(role)) {
        issues.push({
          type: 'not-keyboard-accessible',
          severity: 'serious',
          wcag: '2.1.1',
          description: 'Interactive element not keyboard accessible',
          element: getElementSelector(el)
        });
        penalty += 4;
      }
    });

    // Check for positive tabindex (anti-pattern)
    const positiveTabindex = document.querySelectorAll('[tabindex]');
    positiveTabindex.forEach(el => {
      const tabindex = parseInt(el.getAttribute('tabindex'));
      if (tabindex > 0) {
        issues.push({
          type: 'positive-tabindex',
          severity: 'moderate',
          wcag: '2.4.3',
          description: 'Positive tabindex disrupts natural tab order',
          element: getElementSelector(el)
        });
        penalty += 2;
      }
    });

    return { issues, penalty: Math.min(penalty, 12) };
  }

  /**
   * Check media alternatives
   */
  function checkMediaAlternatives() {
    const issues = [];
    let penalty = 0;

    // Check videos for captions
    const videos = document.querySelectorAll('video');
    videos.forEach(video => {
      const tracks = video.querySelectorAll('track[kind="captions"], track[kind="subtitles"]');
      if (tracks.length === 0) {
        issues.push({
          type: 'video-no-captions',
          severity: 'serious',
          wcag: '1.2.2',
          description: 'Video missing captions/subtitles',
          element: getElementSelector(video)
        });
        penalty += 5;
      }
    });

    // Check audio for transcripts (harder to detect, just note it)
    const audio = document.querySelectorAll('audio');
    if (audio.length > 0) {
      issues.push({
        type: 'audio-transcript-check',
        severity: 'moderate',
        wcag: '1.2.1',
        description: 'Audio elements should have transcripts',
        count: audio.length
      });
      penalty += 2 * audio.length;
    }

    return { issues, penalty: Math.min(penalty, 15) };
  }

  /**
   * Get a CSS selector for an element
   */
  function getElementSelector(el) {
    if (el.id) {
      return `#${el.id}`;
    }
    if (el.className) {
      const classes = Array.from(el.classList).slice(0, 2).join('.');
      return `${el.tagName.toLowerCase()}.${classes}`;
    }
    return el.tagName.toLowerCase();
  }

})();
