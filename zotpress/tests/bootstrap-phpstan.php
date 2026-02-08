<?php
/**
 * PHPStan bootstrap file.
 *
 * @package Zotpress
 */

declare(strict_types=1);

// Define WordPress constants
define( 'ABSPATH', '/tmp/wordpress/' );
define( 'WPINC', 'wp-includes' );
define( 'WP_DEBUG', true );
define( 'ZOTPRESS_VERSION', '8.0.0' );

// Define plugin constants
define( 'ZOTPRESS_PLUGIN_FILE', __DIR__ . '/../zotpress.php' );
define( 'ZOTPRESS_PLUGIN_DIR', dirname( ZOTPRESS_PLUGIN_FILE ) . '/' );
define( 'ZOTPRESS_PLUGIN_URL', 'https://example.com/wp-content/plugins/zotpress/' );
