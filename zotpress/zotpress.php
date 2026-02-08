<?php
/**
 * Plugin Name: Zotpress
 * Plugin URI: https://github.com/hyperpolymath/zotpress
 * Description: Display Zotero citations and bibliographies in WordPress
 * Version: 8.0.0
 * Requires at least: 6.0
 * Requires PHP: 8.1
 * Author: Hyper Polymath
 * Author URI: https://github.com/hyperpolymath
 * License: AGPL-3.0-or-later
 * License URI: https://www.gnu.org/licenses/agpl-3.0.html
 * Text Domain: zotpress
 * Domain Path: /languages
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Plugin constants
define( 'ZOTPRESS_VERSION', '8.0.0' );
define( 'ZOTPRESS_PLUGIN_FILE', __FILE__ );
define( 'ZOTPRESS_PLUGIN_DIR', plugin_dir_path( __FILE__ ) );
define( 'ZOTPRESS_PLUGIN_URL', plugin_dir_url( __FILE__ ) );

/**
 * Initialize Zotpress
 */
function zotpress_init(): void {
    // Load text domain for translations
    load_plugin_textdomain( 'zotpress', false, dirname( plugin_basename( __FILE__ ) ) . '/languages' );

    // Register shortcodes
    require_once ZOTPRESS_PLUGIN_DIR . 'lib/shortcode/shortcode.php';
    add_shortcode( 'zotpress', 'Zotpress_func' );

    // Load in-text citation shortcodes if they exist
    $intext_file = ZOTPRESS_PLUGIN_DIR . 'lib/shortcode/shortcode.intext.php';
    if ( file_exists( $intext_file ) ) {
        require_once $intext_file;
        add_shortcode( 'zotpressInText', 'Zotpress_zotpressInText' );
    }

    $intextbib_file = ZOTPRESS_PLUGIN_DIR . 'lib/shortcode/shortcode.intextbib.php';
    if ( file_exists( $intextbib_file ) ) {
        require_once $intextbib_file;
        add_shortcode( 'zotpressInTextBib', 'Zotpress_zotpressInTextBib' );
    }
}
add_action( 'init', 'zotpress_init' );

/**
 * Initialize admin functionality
 */
function zotpress_admin_init(): void {
    if ( ! is_admin() ) {
        return;
    }

    require_once ZOTPRESS_PLUGIN_DIR . 'lib/admin/admin.php';
    require_once ZOTPRESS_PLUGIN_DIR . 'lib/admin/admin.menu.php';
}
add_action( 'plugins_loaded', 'zotpress_admin_init' );

/**
 * Enqueue frontend styles and scripts
 */
function zotpress_enqueue_assets(): void {
    // Main stylesheet
    $css_file = ZOTPRESS_PLUGIN_DIR . 'dist/css/zotpress.min.css';
    if ( file_exists( $css_file ) ) {
        wp_enqueue_style(
            'zotpress',
            ZOTPRESS_PLUGIN_URL . 'dist/css/zotpress.min.css',
            [],
            ZOTPRESS_VERSION
        );
    } else {
        // Fallback to legacy CSS
        wp_enqueue_style(
            'zotpress',
            ZOTPRESS_PLUGIN_URL . 'css/zotpress.css',
            [],
            ZOTPRESS_VERSION
        );
    }

    // Main script
    $js_file = ZOTPRESS_PLUGIN_DIR . 'dist/js/zotpress.min.js';
    if ( file_exists( $js_file ) ) {
        wp_enqueue_script(
            'zotpress',
            ZOTPRESS_PLUGIN_URL . 'dist/js/zotpress.min.js',
            [],
            ZOTPRESS_VERSION,
            true
        );
    }

    // Localize script with AJAX URL
    wp_localize_script( 'zotpress', 'zpAjax', [
        'ajaxUrl' => admin_url( 'admin-ajax.php' ),
        'nonce'   => wp_create_nonce( 'zotpress_ajax' ),
    ] );
}
add_action( 'wp_enqueue_scripts', 'zotpress_enqueue_assets' );

/**
 * Activation hook
 */
function zotpress_activate(): void {
    // Set default options
    if ( ! get_option( 'Zotpress_DefaultStyle' ) ) {
        update_option( 'Zotpress_DefaultStyle', 'apa' );
    }

    // Flush rewrite rules
    flush_rewrite_rules();
}
register_activation_hook( __FILE__, 'zotpress_activate' );

/**
 * Deactivation hook
 */
function zotpress_deactivate(): void {
    flush_rewrite_rules();
}
register_deactivation_hook( __FILE__, 'zotpress_deactivate' );
