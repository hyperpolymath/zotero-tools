<?php
/**
 * PHPUnit bootstrap file for Zotpress tests.
 *
 * @package Zotpress
 */

declare(strict_types=1);

// Define WordPress constants for testing
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', '/tmp/wordpress/' );
}
if ( ! defined( 'WPINC' ) ) {
    define( 'WPINC', 'wp-includes' );
}
if ( ! defined( 'WP_DEBUG' ) ) {
    define( 'WP_DEBUG', true );
}
if ( ! defined( 'ZOTPRESS_VERSION' ) ) {
    define( 'ZOTPRESS_VERSION', '8.0.0' );
}
if ( ! defined( 'ZOTPRESS_TESTING' ) ) {
    define( 'ZOTPRESS_TESTING', true );
}

// Composer autoloader
$autoloader = __DIR__ . '/../vendor/autoload.php';
if ( file_exists( $autoloader ) ) {
    require_once $autoloader;
}

// Load WordPress test utilities if available
$wp_tests_dir = getenv( 'WP_TESTS_DIR' );
if ( $wp_tests_dir ) {
    require_once $wp_tests_dir . '/includes/functions.php';
    require_once $wp_tests_dir . '/includes/bootstrap.php';
}

// Load plugin files
require_once __DIR__ . '/../lib/request/request.functions.php';
