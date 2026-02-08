/**
 * Zotpress Build Script
 *
 * Main entry point for building CSS and JS assets.
 * Uses Deno for modern, secure builds.
 *
 * @module
 */

import { ensureDir } from '@std/fs';
import { join } from '@std/path';

const DIST_DIR = './dist';

/**
 * Ensure output directories exist
 */
async function setupDirs() {
  await ensureDir(join(DIST_DIR, 'css'));
  await ensureDir(join(DIST_DIR, 'js'));
}

/**
 * Run a Deno task
 */
async function runTask(taskName) {
  const command = new Deno.Command('deno', {
    args: ['task', taskName],
    stdout: 'inherit',
    stderr: 'inherit',
  });
  const { code } = await command.output();
  if (code !== 0) {
    throw new Error(`Task ${taskName} failed with code ${code}`);
  }
}

/**
 * Build ReScript sources
 */
async function buildReScript() {
  console.log('📦 Building ReScript...');
  const command = new Deno.Command('npx', {
    args: ['rescript', 'build'],
    stdout: 'inherit',
    stderr: 'inherit',
  });
  const { code } = await command.output();
  if (code !== 0) {
    console.warn('⚠️  ReScript build had issues (may need dependencies installed)');
  }
}

/**
 * Main build function
 */
async function main() {
  const startTime = performance.now();

  console.log('🔨 Starting Zotpress build...\n');

  try {
    // Setup directories
    console.log('📁 Setting up directories...');
    await setupDirs();

    // Build ReScript first (compiles to JS)
    await buildReScript();

    // Build assets
    console.log('🎨 Building CSS...');
    await runTask('build:css');

    console.log('⚡ Building JavaScript...');
    await runTask('build:js');

    const duration = ((performance.now() - startTime) / 1000).toFixed(2);
    console.log(`\n✓ Build complete in ${duration}s`);
  } catch (error) {
    console.error('\n❌ Build failed:', error.message);
    Deno.exit(1);
  }
}

// Run if executed directly
if (import.meta.main) {
  main();
}

export { buildReScript, main, runTask, setupDirs };
