#!/usr/bin/env node

/**
 * Create or update a moving major version tag (e.g., v1) pointing to the latest
 * release tag (e.g., v1.2.3).
 *
 * semantic-release invokes this script via @semantic-release/exec successCmd
 * with ${nextRelease.version} as the first argument.
 */

import { execSync } from 'node:child_process';

function run(cmd) {
  execSync(cmd, { stdio: 'inherit' });
}

const rawVersion = process.argv[2];

if (!rawVersion) {
  console.error('tag-major.js: missing version argument');
  process.exit(1);
}

if (!/^v?\d+\.\d+\.\d+$/.test(rawVersion)) {
  console.error(`tag-major.js: invalid semver version "${rawVersion}"`);
  process.exit(1);
}

// Ensure we're in a git repo
run('git rev-parse --is-inside-work-tree');

// semantic-release sometimes passes bare semver (1.2.3); normalize to v1.2.3
const canonicalVersion = rawVersion.startsWith('v') ? rawVersion : `v${rawVersion}`;

const major = canonicalVersion.replace(/^v(\d+)\..*/, 'v$1');

console.log(`Updating major tag ${major} -> ${canonicalVersion}`);

// Force-create or update the lightweight tag locally
run(`git tag -f ${major} ${canonicalVersion}`);

// Push the updated major tag
run(`git push --force origin ${major}`);
