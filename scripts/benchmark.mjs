// Capture measured results and context; no invented scores or time thresholds.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { cpus, platform, arch, release } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const quick = process.argv.includes('--quick');
const labelIndex = process.argv.indexOf('--label');
const label = labelIndex < 0 ? 'current' : process.argv[labelIndex + 1];
assert.ok(['current', 'before', 'after'].includes(label), 'label must be current/before/after');
function command(program, args) {
  const result = spawnSync(program, args, { cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 16 * 1024 * 1024 });
  assert.ifError(result.error);
  assert.equal(result.status, 0, result.stderr);
  return result.stdout;
}
const result = JSON.parse(command('moon', [
  'run', '--release', 'examples/performance', ...(quick ? ['--', '--quick'] : []),
]));
assert.equal(result.unit, 'microseconds');
assert.equal(result.includes_io_or_startup, false);
for (const row of result.cases) {
  assert.equal(row.observed_findings, row.expected_findings);
  for (const stage of [row.parse, row.analyze]) {
    assert.equal(stage.samples_us.length, result.samples_per_case);
    assert.ok(stage.samples_us.every(x => Number.isFinite(x) && x >= 0));
    assert.ok(stage.min_us <= stage.mean_us && stage.mean_us <= stage.max_us);
  }
}
const record = {
  captured_at: new Date().toISOString(),
  source_commit: command('git', ['rev-parse', 'HEAD']).trim(),
  worktree_dirty: command('git', ['status', '--porcelain']).trim().length > 0,
  source_sha256: Object.fromEntries(['analyzer.mbt', 'examples/performance/main.mbt'].map(
    file => [file, createHash('sha256').update(readFileSync(path.join(root, file))).digest('hex')],
  )),
  toolchain: command('moon', ['version', '--all', '--no-path']).trim(),
  host: { platform: platform(), arch: arch(), release: release(), cpu: cpus()[0]?.model },
  target: 'wasm', mode: 'release', ...result,
};
const directory = path.join(root, '_build', 'benchmarks');
mkdirSync(directory, { recursive: true });
const output = path.join(directory, label + (quick ? '-quick.json' : '-full.json'));
writeFileSync(output, JSON.stringify(record, null, 2) + '\n');
console.log(JSON.stringify(record, null, 2));
console.error('Recorded measured benchmark: ' + output);
