// Real subprocess tests. All generated input belongs to this temporary directory.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const target = process.argv[2] ?? 'wasm';
assert.ok(['wasm', 'wasm-gc', 'js', 'native'].includes(target), 'unsupported test target');
const built = spawnSync('moon', ['build', '--release', '--target', target], {
  cwd: root, encoding: 'utf8', timeout: 120000,
});
assert.ifError(built.error);
assert.equal(built.status, 0, built.stderr);
const ext = target === 'js' ? 'js' : target === 'native' ? 'exe' : 'wasm';
const output = path.join(root, '_build', target, 'release', 'build', 'cmd', 'main', 'main.' + ext);
const launcher = target === 'js' ? process.execPath : target === 'native' ? output : 'moonrun';
const prefix = target === 'native' ? [] : target === 'js' ? [output] : [output, '--'];
let checks = 0;
function run(args, code = 0, json = true) {
  const result = spawnSync(launcher, [...prefix, ...args], {
    cwd: root, encoding: 'utf8', timeout: 30000, maxBuffer: 32 * 1024 * 1024,
  });
  assert.ifError(result.error);
  assert.equal(result.signal, null);
  assert.equal(result.status, code, result.stderr + '\n' + result.stdout);
  assert.doesNotMatch(result.stderr + result.stdout, /RuntimeError|unreachable|stack trace/i);
  if (code !== 0) assert.ok(result.stderr.trim(), 'failure needs a human diagnostic on stderr');
  else assert.equal(result.stderr, '');
  checks++;
  return json ? JSON.parse(result.stdout) : result;
}
const temp = mkdtempSync(path.join(tmpdir(), 'moonkeyguard-cli-'));
try {
  const file = path.join(temp, '中文 配置.keymap');
  const content = 'keymap name=场景\r\nbind 保存 command=保存 keys=Ctrl+S\r\n';
  writeFileSync(file, '\uFEFF' + content, 'utf8');
  const before = createHash('sha256').update(readFileSync(file)).digest('hex');
  const flags = ['--format', 'json'];
  assert.equal(run(['--input', file, ...flags]).analysis.checked_bindings, 1);
  assert.equal(run(['--input', file, '--metrics', '--suggest', ...flags]).metrics.bindings, 1);
  assert.equal(run(['--source', '', ...flags]).analysis.checked_bindings, 0);
  assert.match(run(['--help'], 0, false).stdout, /--baseline/);
  run(['--bad-option'], 2, false);
  run(['--input'], 2, false);
  run(['--input', file, '--source', ''], 2, false);
  run(['--format', 'jsoon'], 2, false);
  run(['--baseline', file], 2, false);
  run(['--format', 'sarif', '--suggest'], 2, false);
  assert.equal(run(['--input', path.join(temp, 'missing'), ...flags], 2).ok, false);
  run(['--input', temp, ...flags], 2);
  run(['--source', 'wat value=1', ...flags], 2);
  const conflict = 'bind a command=a keys=Ctrl+A\nbind b command=b keys=Ctrl+A';
  assert.equal(run(['--source', conflict, ...flags]).analysis.errors, 1);
  run(['--source', conflict, '--fail-on-error', ...flags], 1);
  const warning = 'bind a command=a keys=Ctrl+K\nbind b command=b keys=Ctrl+K,Ctrl+C';
  run(['--source', warning, '--fail-on-error', ...flags]);
  run(['--source', warning, '--fail-on-warning', ...flags], 1);
  run(['--source', conflict, '--max-bindings', '1', ...flags], 2);
  const bad = path.join(temp, 'invalid-utf8.keymap');
  writeFileSync(bad, Buffer.from([0xc3, 0x28]));
  assert.match(run(['--input', bad, ...flags], 2).error, /UTF-8/);
  const large = path.join(temp, 'large.keymap');
  writeFileSync(large, ' '.repeat(2097153));
  assert.match(run(['--input', large, ...flags], 2).error, /2 MiB/);
  writeFileSync(large, ' '.repeat(1048577));
  assert.match(run(['--input', large, ...flags], 2).error, /UTF-16/);
  const baseline = 'examples/review/baseline.keymap';
  const regression = run(['--input', 'examples/review/regression.keymap', '--baseline', baseline, ...flags], 1);
  assert.equal(regression.baseline.new_errors, 1);
  const fixed = run(['--input', 'examples/review/fixed.keymap', '--baseline', baseline, ...flags]);
  assert.equal(fixed.baseline.new_errors, 0);
  assert.equal(fixed.baseline.retained_count, 1);
  run(['--input', file, '--baseline', bad, ...flags], 2);
  assert.equal(run(['--input', file, '--format', 'sarif']).version, '2.1.0');
  assert.equal(createHash('sha256').update(readFileSync(file)).digest('hex'), before, 'input file was modified');
  // A large successful JSON document must be complete when stdout is a pipe.
  const dense = Array.from({ length: 100 }, (_, i) => 'bind b' + i + ' command=c' + i + ' keys=Ctrl+K').join('\n');
  writeFileSync(large, dense);
  assert.equal(run(['--input', large, ...flags]).analysis.findings.length, 4950);
  console.log('PASS: ' + checks + ' real CLI subprocess cases on ' + target + '; input unchanged; large JSON pipe complete.');
} finally {
  // mkdtemp created this exact directory; never remove a supplied input path.
  assert.ok(temp.startsWith(path.join(tmpdir(), 'moonkeyguard-cli-')));
  rmSync(temp, { recursive: true, force: true });
}
