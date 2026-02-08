<?php
/**
 * Zotpress API Test - Standalone PHP Script
 *
 * Test your Zotero API connection without WordPress.
 * Run: php demo/test-api.php YOUR_USER_ID [YOUR_API_KEY]
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

if (php_sapi_name() !== 'cli') {
    die("This script must be run from the command line.\n");
}

if ($argc < 2) {
    echo "Usage: php test-api.php USER_ID [API_KEY]\n\n";
    echo "Example:\n";
    echo "  php test-api.php 123456\n";
    echo "  php test-api.php 123456 abcDEF123xyz\n\n";
    echo "Get your credentials at: https://www.zotero.org/settings/keys\n";
    exit(1);
}

$userId = $argv[1];
$apiKey = $argv[2] ?? null;

echo "Zotpress API Test\n";
echo "=================\n\n";
echo "User ID: $userId\n";
echo "API Key: " . ($apiKey ? '***' . substr($apiKey, -4) : '(none - public access only)') . "\n\n";

// Build request
$url = "https://api.zotero.org/users/$userId/items?limit=5&format=json&v=3";
$headers = ['Accept: application/json'];
if ($apiKey) {
    $headers[] = "Zotero-API-Key: $apiKey";
}

echo "Fetching from: $url\n\n";

// Make request
$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $url,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => $headers,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_TIMEOUT => 30,
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "CURL Error: $error\n";
    exit(1);
}

if ($httpCode !== 200) {
    echo "HTTP Error: $httpCode\n";
    echo "Response: $response\n";
    exit(1);
}

$items = json_decode($response, true);

if (empty($items)) {
    echo "No items found.\n";
    echo "- Check if your User ID is correct\n";
    echo "- Make your library public or provide an API key\n";
    exit(0);
}

echo "Found " . count($items) . " item(s):\n";
echo str_repeat("-", 60) . "\n\n";

foreach ($items as $item) {
    $data = $item['data'];
    $title = $data['title'] ?? 'Untitled';
    $type = $data['itemType'] ?? 'unknown';
    $key = $item['key'];

    // Get authors
    $authors = [];
    foreach (($data['creators'] ?? []) as $creator) {
        if (($creator['creatorType'] ?? '') === 'author') {
            $authors[] = $creator['lastName'] ?? $creator['name'] ?? '';
        }
    }
    $authorStr = implode(', ', $authors) ?: 'Unknown';

    // Get year
    $year = '';
    if (isset($data['date']) && preg_match('/\d{4}/', $data['date'], $m)) {
        $year = $m[0];
    }

    echo "Title:   $title\n";
    echo "Authors: $authorStr" . ($year ? " ($year)" : "") . "\n";
    echo "Type:    $type\n";
    echo "Key:     $key\n";
    echo "\n";
}

echo str_repeat("-", 60) . "\n";
echo "\nWordPress shortcode:\n";
echo "[zotpress userid=\"$userId\" limit=\"5\"]\n\n";
echo "For a specific item:\n";
echo "[zotpress item=\"" . $items[0]['key'] . "\"]\n";
