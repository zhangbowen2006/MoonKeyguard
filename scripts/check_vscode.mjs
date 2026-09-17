// Consumer B: call compiled MoonBit directly in Node; no moonrun subprocess.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
try {
  const args = process.argv.slice(2);
  if (args.length !== 5) throw new Error('Usage: node scripts/check_vscode.mjs DEFAULTS EXTENSION OVERRIDES SCENARIOS windows|mac|linux');
  const { audit_json } = await import(pathToFileURL(path.join(root, '_build/js/release/build/vscode/vscode.js')).href);
  const sources = args.slice(0, 4).map(file => {
    const bytes = readFileSync(file);
    if (bytes.length > 2097152) throw new Error(file + ': input exceeds 2 MiB');
    return new TextDecoder('utf-8', { fatal: true }).decode(bytes);
  });
  const report = JSON.parse(audit_json(...sources, args[4]));
  console.log(JSON.stringify(report, null, 2));
  if (report.exit_code !== 0) console.error('MoonKeyguard VS Code contract: ' + report.status);
  process.exitCode = report.exit_code;
} catch (error) {
  console.error('MoonKeyguard: ' + error.message);
  process.exitCode = 2;
}
