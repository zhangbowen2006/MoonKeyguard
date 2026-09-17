// Conformance to the declared subset + parity of TWO consumers of the same kernel.
// This is NOT an actual VS Code GUI/keyboard-layout conformance run.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import vm from 'node:vm';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const base = path.join(root, 'examples/vscode-review');
function execute(program, args, expected = 0) {
  const result = spawnSync(program, args, { cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 8 * 1024 * 1024 });
  assert.ifError(result.error);
  assert.equal(result.status, expected, result.stderr);
  assert.doesNotMatch(result.stderr, /RuntimeError|unreachable/);
  return result;
}
execute('moon', ['build', '--target', 'wasm', '--release']);
execute('moon', ['build', '--target', 'js', '--release']);
const { audit_json } = await import(pathToFileURL(path.join(root, '_build/js/release/build/vscode/vscode.js')).href);
const wasm = path.join(root, '_build/wasm/release/build/cmd/main/main.wasm');
const inputs = ['overrides.jsonc', 'scenarios.json'].map(file => path.join(base, file));
const evidence = [];
for (const platform of ['windows', 'mac', 'linux']) {
  for (const broken of [false, true]) {
    const defaults = path.join(base, platform === 'mac' ? 'defaults.mac.jsonc' : 'defaults.jsonc');
    const extension = path.join(base, 'extension', broken ? 'package.regression.json' : 'package.json');
    const sources = [defaults, extension, ...inputs].map(file => readFileSync(file, 'utf8'));
    const library = JSON.parse(audit_json(...sources, platform));
    const expected = broken ? 1 : 0;
    assert.equal(library.exit_code, expected);
    assert.equal(library.regressions, broken ? 3 : 0);
    assert.equal(library.inconclusive, 0);
    const command = execute('moonrun', [wasm, '--', 'vscode',
      '--defaults', defaults, '--extension', extension, '--overrides', inputs[0],
      '--scenarios', inputs[1], '--platform', platform], expected);
    assert.deepEqual(JSON.parse(command.stdout), library, 'CLI and direct JS call must agree');
    const node = execute(process.execPath, [path.join(root, 'scripts/check_vscode.mjs'), defaults, extension, ...inputs, platform], expected);
    assert.deepEqual(JSON.parse(node.stdout), library, 'standalone Node consumer must agree');
    evidence.push({ platform, fixture: broken ? 'injected-regression' : 'fixed-extension', report: library });
  }
}
// Exercise the real example command handler against a minimal mock host.
// No actual editor is launched; neither this test nor its result claims one was.
const callbacks = new Map();
const contexts = [];
let replacement = null;
const mock = {
  commands: {
    executeCommand: async (...args) => { contexts.push(args); },
    registerCommand: (id, callback) => { callbacks.set(id, callback); return { dispose() {} }; },
  },
  window: {
    showInformationMessage: () => {},
    activeTextEditor: {
      selection: { isEmpty: false },
      document: { getText: () => 'selected' },
      edit: async callback => { callback({ replace: (_selection, text) => { replacement = text; } }); },
    },
  },
};
const api = {};
vm.runInNewContext(readFileSync(path.join(base, 'extension/extension.cjs'), 'utf8'), {
  require: name => { assert.equal(name, 'vscode'); return mock; },
  exports: api,
}, { filename: 'extension.cjs', timeout: 1000 });
await api.activate({ subscriptions: [] });
await callbacks.get('keyguard.wrapSelection')();
assert.equal(replacement, null);
await callbacks.get('keyguard.toggleWrapMode')();
await callbacks.get('keyguard.wrapSelection')();
assert.equal(replacement, '[selected]');
assert.equal(contexts.at(-1)[2], true);
const out = path.join(root, '_build/host-evidence');
mkdirSync(out, { recursive: true });
writeFileSync(path.join(out, 'vscode-consumers.json'), JSON.stringify({
  recorded_at: new Date().toISOString(),
  scope: 'supplied fixtures, documented boolean subset; not live VS Code',
  consumers: ['MoonBit/wasm CLI', 'direct compiled-JS API', 'standalone Node caller'],
  comparisons: 12,
  mock_extension_handler: 'passed (not an actual VS Code host)',
  evidence,
}, null, 2) + '\n');
console.log('PASS: 6 fixture/platform cases, 12 cross-consumer comparisons, plus mock-host extension handler.');
