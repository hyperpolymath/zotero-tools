<?php
/**
 * Example unit test for Zotpress.
 *
 * @package Zotpress\Tests\Unit
 */

declare(strict_types=1);

namespace Zotpress\Tests\Unit;

use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\Attributes\CoversNothing;

/**
 * Example test class demonstrating PHPUnit 10+ patterns.
 */
#[CoversNothing]
final class ExampleTest extends TestCase {

    /**
     * Test that true is true (sanity check).
     */
    #[Test]
    public function it_passes_sanity_check(): void {
        $this->assertTrue( true );
    }

    /**
     * Test constants are defined.
     */
    #[Test]
    public function it_has_required_constants(): void {
        $this->assertTrue( defined( 'ZOTPRESS_TESTING' ) );
        $this->assertTrue( ZOTPRESS_TESTING );
    }

    /**
     * Test version constant format.
     */
    #[Test]
    public function it_has_valid_version_format(): void {
        $this->assertMatchesRegularExpression(
            '/^\d+\.\d+\.\d+$/',
            ZOTPRESS_VERSION
        );
    }
}
