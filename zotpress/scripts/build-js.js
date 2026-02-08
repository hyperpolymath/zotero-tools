/**
 * JavaScript Build Script
 *
 * Bundles ReScript-compiled JS and legacy JavaScript with esbuild.
 * Produces optimized bundles for WordPress plugin.
 *
 * @module
 */

import { ensureDir } from '@std/fs';
import { join, basename } from '@std/path';
import * as esbuild from 'esbuild';

const RESCRIPT_OUT_DIR = './lib/es6';
const LEGACY_JS_DIR = './js';
const DIST_DIR = './dist/js';

/**
 * JS build configuration
 */
const config = {
  minify: Deno.env.get('NODE_ENV') === 'production',
  sourceMaps: Deno.env.get('NODE_ENV') !== 'production',
  target: ['es2020', 'chrome90', 'firefox90', 'safari14'],
};

/**
 * Bundle ReScript-compiled JavaScript with esbuild
 */
async function bundleReScript(inputPath, outputPath) {
  const filename = basename(inputPath);
  console.log(`  Bundling: ${filename}`);

  const result = await esbuild.build({
    entryPoints: [inputPath],
    outfile: outputPath,
    bundle: true,
    minify: config.minify,
    sourcemap: config.sourceMaps,
    target: config.target,
    format: 'iife',
    globalName: 'Zotpress',
    platform: 'browser',
    external: ['jquery', 'wp'],
    define: {
      'process.env.NODE_ENV': JSON.stringify(Deno.env.get('NODE_ENV') || 'development'),
    },
    metafile: true,
  });

  if (result.metafile) {
    const outputs = Object.values(result.metafile.outputs)[0];
    if (outputs) {
      console.log(`    → ${outputs.bytes} bytes`);
    }
  }
}

/**
 * Minify a legacy JavaScript file
 */
async function minifyFile(inputPath, outputPath) {
  const filename = basename(inputPath);
  console.log(`  Minifying: ${filename}`);

  const code = await Deno.readTextFile(inputPath);

  const result = await esbuild.transform(code, {
    minify: true,
    sourcemap: config.sourceMaps,
    target: config.target,
  });

  await Deno.writeTextFile(outputPath, result.code);

  if (result.map && config.sourceMaps) {
    await Deno.writeTextFile(`${outputPath}.map`, result.map);
  }

  const inputSize = new TextEncoder().encode(code).length;
  const outputSize = new TextEncoder().encode(result.code).length;
  const reduction = ((1 - outputSize / inputSize) * 100).toFixed(1);

  console.log(`    ${inputSize} → ${outputSize} bytes (${reduction}% reduction)`);
}

/**
 * Find all JS files in a directory
 */
async function findJSFiles(dir, extensions = ['.js', '.res.js']) {
  const files = [];

  try {
    for await (const entry of Deno.readDir(dir)) {
      if (entry.isFile) {
        const isTarget = extensions.some(
          (ext) => entry.name.endsWith(ext) && !entry.name.endsWith('.min.js')
        );
        if (isTarget) {
          files.push(join(dir, entry.name));
        }
      }
    }
  } catch {
    // Directory may not exist yet
  }

  return files;
}

/**
 * Main JS build function
 */
async function main() {
  console.log('⚡ Building JavaScript assets...\n');

  await ensureDir(DIST_DIR);

  // Build ReScript-compiled JS
  const resFiles = await findJSFiles(RESCRIPT_OUT_DIR, ['.res.js']);
  if (resFiles.length > 0) {
    console.log(`Found ${resFiles.length} ReScript files in ${RESCRIPT_OUT_DIR}:`);
    for (const file of resFiles) {
      const outputFile = join(DIST_DIR, basename(file).replace('.res.js', '.min.js'));
      await bundleReScript(file, outputFile);
    }
  } else {
    console.log('No ReScript output found (run `deno task build:rescript` first)');
  }

  // Minify legacy JavaScript files
  const legacyFiles = await findJSFiles(LEGACY_JS_DIR, ['.js']);
  if (legacyFiles.length > 0) {
    console.log(`\nFound ${legacyFiles.length} legacy files in ${LEGACY_JS_DIR}:`);
    for (const file of legacyFiles) {
      const filename = basename(file);
      // Skip already minified files
      if (filename.includes('.min.')) continue;

      const outputFile = join(DIST_DIR, filename.replace('.js', '.min.js'));
      await minifyFile(file, outputFile);
    }
  }

  // Stop esbuild service
  await esbuild.stop();

  console.log('\n✓ JavaScript build complete');
}

// Run if executed directly
if (import.meta.main) {
  main();
}

export { bundleReScript, findJSFiles, main, minifyFile };
