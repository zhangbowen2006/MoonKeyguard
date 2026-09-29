// Keep the copy-ready proposal aligned with the public repository and module.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = relative => readFileSync(path.join(root, relative), 'utf8').replace(/\r\n/g, '\n');
const proposal = read('docs/PROJECT_PROPOSAL.md');
const submission = read('submission/MoonKeyguard_9月黑客松申报书_报名版.md');
const moduleText = read('moon.mod');
const readField = name => {
  const match = moduleText.match(new RegExp(`^\\s*${name}\\s*=\\s*"([^"]+)"`, 'm'));
  assert.ok(match, `moon.mod missing ${name}`);
  return match[1];
};
const moduleName = readField('name');
const version = readField('version');
const repository = readField('repository').replace(/\.git$/, '');

assert.equal(submission, proposal, 'Copy-ready proposal differs from docs/PROJECT_PROPOSAL.md');
assert.equal(repository, 'https://github.com/zhangbowen2006/MoonKeyguard');
assert.equal(moduleName, 'zhangbowen2006/moonkeyguard');
for (const required of [
  '# MoonKeyguard｜VS Code 扩展快捷键行为回归检查',
  '申请人：张博文',
  `项目仓库：${repository}`,
  `MoonBit 模块：\`${moduleName}\``,
  `\`${version}\` 已发布至 Mooncakes`,
  '功能边界与验收证据',
]) {
  assert.ok(proposal.includes(required), `Proposal missing: ${required}`);
}
for (const stale of ['MoonBitTargetParity', '桌面应用、终端工具、编辑器', '生产 MoonBit 代码约 6.1k 行']) {
  assert.ok(!proposal.includes(stale), `Proposal contains stale subject: ${stale}`);
}
console.log('PASS: copy-ready proposal matches the canonical proposal and MoonBit repository metadata.');
