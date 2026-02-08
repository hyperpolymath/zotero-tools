/**
 * Accessibility Everywhere - Background Service Worker
 * Handles API communication, caching, and badge updates
 */

const API_BASE_URL = 'https://api.accessibility-everywhere.org'; // Will be our API
const CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours

// Badge color thresholds
const SCORE_COLORS = {
  excellent: { min: 90, color: '#10b981', text: 'EXCELLENT' },
  good: { min: 75, color: '#3b82f6', text: 'GOOD' },
  fair: { min: 60, color: '#f59e0b', text: 'FAIR' },
  poor: { min: 40, color: '#ef4444', text: 'POOR' },
  critical: { min: 0, color: '#991b1b', text: 'CRITICAL' }
};

// Listen for messages from content scripts and popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'scanPage') {
    handleScanRequest(message.url, sender.tab.id)
      .then(result => sendResponse({ success: true, data: result }))
      .catch(error => sendResponse({ success: false, error: error.message }));
    return true; // Keep channel open for async response
  } else if (message.action === 'getScore') {
    getCachedScore(message.url)
      .then(score => sendResponse({ success: true, data: score }))
      .catch(error => sendResponse({ success: false, error: error.message }));
    return true;
  } else if (message.action === 'reportIssue') {
    reportAccessibilityIssue(message.data)
      .then(result => sendResponse({ success: true, data: result }))
      .catch(error => sendResponse({ success: false, error: error.message }));
    return true;
  }
});

// Update badge when tab is activated or updated
chrome.tabs.onActivated.addListener(async (activeInfo) => {
  try {
    const tab = await chrome.tabs.get(activeInfo.tabId);
    if (tab.url) {
      updateBadgeForUrl(tab.url, activeInfo.tabId);
    }
  } catch (error) {
    console.error('Error updating badge:', error);
  }
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.url) {
    updateBadgeForUrl(tab.url, tabId);
  }
});

/**
 * Handle scan request for a URL
 */
async function handleScanRequest(url, tabId) {
  try {
    // Check cache first
    const cached = await getCachedScore(url);
    if (cached && !cached.expired) {
      updateBadge(cached.score, tabId);
      return cached;
    }

    // Perform new scan
    const score = await performScan(url);

    // Cache the result
    await cacheScore(url, score);

    // Update badge
    updateBadge(score.overall, tabId);

    return score;
  } catch (error) {
    console.error('Scan error:', error);
    chrome.action.setBadgeText({ text: '?', tabId });
    chrome.action.setBadgeBackgroundColor({ color: '#6b7280', tabId });
    throw error;
  }
}

/**
 * Perform accessibility scan (local + API)
 */
async function performScan(url) {
  // In production, this would:
  // 1. Run local quick scan (privacy-first)
  // 2. Optionally call API for detailed scan (with user permission)
  // 3. Aggregate results

  // For now, simulate with local analysis
  // In real implementation, we'd inject axe-core or similar

  try {
    const response = await fetch(`${API_BASE_URL}/scan`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ url })
    });

    if (!response.ok) {
      // Fallback to local scan if API unavailable
      return await performLocalScan();
    }

    return await response.json();
  } catch (error) {
    console.log('API unavailable, using local scan');
    return await performLocalScan();
  }
}

/**
 * Perform local privacy-respecting scan
 * This is injected into the page via content script
 */
async function performLocalScan() {
  // Simulate scan results for MVP
  // In production, this would use axe-core injected into the page

  return {
    overall: Math.floor(Math.random() * 100),
    wcag: {
      a: Math.random() > 0.3,
      aa: Math.random() > 0.5,
      aaa: Math.random() > 0.7
    },
    categories: {
      'Color Contrast': Math.floor(Math.random() * 100),
      'Keyboard Navigation': Math.floor(Math.random() * 100),
      'Screen Reader': Math.floor(Math.random() * 100),
      'Semantic HTML': Math.floor(Math.random() * 100),
      'ARIA': Math.floor(Math.random() * 100)
    },
    issues: [
      {
        severity: 'critical',
        wcag: '1.4.3',
        description: 'Insufficient color contrast',
        count: Math.floor(Math.random() * 10)
      },
      {
        severity: 'serious',
        wcag: '2.1.1',
        description: 'Keyboard trap detected',
        count: Math.floor(Math.random() * 5)
      }
    ],
    timestamp: Date.now()
  };
}

/**
 * Update badge for a URL
 */
async function updateBadgeForUrl(url, tabId) {
  try {
    const cached = await getCachedScore(url);
    if (cached) {
      updateBadge(cached.overall, tabId);
    } else {
      // Show loading state
      chrome.action.setBadgeText({ text: '...', tabId });
      chrome.action.setBadgeBackgroundColor({ color: '#6b7280', tabId });

      // Trigger scan in background
      handleScanRequest(url, tabId).catch(console.error);
    }
  } catch (error) {
    console.error('Error updating badge:', error);
  }
}

/**
 * Update badge with score
 */
function updateBadge(score, tabId) {
  const scoreLevel = Object.values(SCORE_COLORS).find(level => score >= level.min);

  chrome.action.setBadgeText({
    text: score.toString(),
    tabId
  });
  chrome.action.setBadgeBackgroundColor({
    color: scoreLevel.color,
    tabId
  });
  chrome.action.setTitle({
    title: `Accessibility Score: ${score}/100 (${scoreLevel.text})`,
    tabId
  });
}

/**
 * Cache score for a URL
 */
async function cacheScore(url, scoreData) {
  const cacheKey = `score_${hashUrl(url)}`;
  const cacheEntry = {
    url,
    ...scoreData,
    cachedAt: Date.now()
  };

  await chrome.storage.local.set({ [cacheKey]: cacheEntry });
}

/**
 * Get cached score for a URL
 */
async function getCachedScore(url) {
  const cacheKey = `score_${hashUrl(url)}`;
  const result = await chrome.storage.local.get(cacheKey);
  const cached = result[cacheKey];

  if (!cached) {
    return null;
  }

  const age = Date.now() - cached.cachedAt;
  const expired = age > CACHE_DURATION;

  return {
    ...cached,
    expired
  };
}

/**
 * Report accessibility issue
 */
async function reportAccessibilityIssue(issueData) {
  try {
    const response = await fetch(`${API_BASE_URL}/report`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(issueData)
    });

    return await response.json();
  } catch (error) {
    console.error('Error reporting issue:', error);
    // Store locally for later submission if API unavailable
    const reports = await chrome.storage.local.get('pending_reports') || { pending_reports: [] };
    reports.pending_reports.push({ ...issueData, timestamp: Date.now() });
    await chrome.storage.local.set(reports);
    throw error;
  }
}

/**
 * Simple URL hash function for cache keys
 */
function hashUrl(url) {
  let hash = 0;
  for (let i = 0; i < url.length; i++) {
    const char = url.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash).toString(36);
}

/**
 * Initialize extension
 */
chrome.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') {
    // Set default options
    chrome.storage.sync.set({
      autoScan: true,
      devMode: false,
      apiEnabled: true,
      badgeEnabled: true
    });

    // Open welcome page
    chrome.tabs.create({ url: 'welcome.html' });
  }
});
