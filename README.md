# MoonKeyguard

开发状态：以下文件输入、CLI 退出码和性能测量为 **Unreleased 本地改进**，
尚未发布到 Mooncakes；已发布的 0.2.0 与其验证记录保持不变。
本轮 CI 配置新增的检查也须等后续推送后才有远程运行记录。

MoonKeyguard 本轮聚焦 **VS Code 扩展快捷键的发布前行为回归检查**：
维护者提交相关默认规则、扩展 package.json、用户覆盖配置，以及“在这个状态下应该触发哪个命令”的场景契约。
同一组按键只改了 when 条件，也可能让普通编辑模式下的“保存”变成某个扩展命令；
本工具给出实际选中规则、条件判定和预期差异，方便在 CI 中拦截这种变化。

目标用户是需要维护多状态、多平台快捷键行为的 VS Code 扩展或键位包作者。
如果只是给自己的编辑器改几个快捷键，优先使用 VS Code 内置同键查看和排障日志，无需引入本库。
它不是所有编辑器的通用解析器，更不替代 VS Code 对真实键盘、布局、焦点和命令执行的最终判定。
本项目与八月 MoonBVHKit 的选题、仓库和核心实现独立。

## 先看一个可以复验的用途

```sh
moon run cmd/main -- vscode --defaults examples/vscode-review/defaults.jsonc --extension examples/vscode-review/extension/package.regression.json --overrides examples/vscode-review/overrides.jsonc --scenarios examples/vscode-review/scenarios.json --platform windows
```

预期退出 1，普通保存、有选区但未开启模式、只读编辑三个状态发生回归。
把 extension 参数改为同目录的 `package.json` 后，五个状态应通过，退出 0。
反例和修复的按键均为 Ctrl+S：这里检查的是条件变化造成的行为回归，不是简单找重复字符串。
这是原创的开发扩展和故障注入样例，**不是实际客户采用或线上故障记录**。

同一个纯 MoonBit 内核也可以直接从 Node 调用，完全不启动 moonrun：

```sh
moon build --release --target js
node scripts/check_vscode.mjs examples/vscode-review/defaults.jsonc examples/vscode-review/extension/package.json examples/vscode-review/overrides.jsonc examples/vscode-review/scenarios.json windows
```

入口 `@vscode.audit_sources` / 导出 `audit_json` 共享原生格式导入、when 判定、规则顺序和报告；
两个调用端只负责文件和进程边界。详见 [宿主边界](docs/HOST_PROFILE.md)、
[场景复现及手工实机核对](examples/vscode-review/README.md) 和 [为什么独立成库](docs/USE_CASE_AND_VALUE.md)。

## 兼容保留的 DSL 基础能力

- 用轻量 DSL 表达 `bind`、`context`、`reserve` 和 `keymap` 声明，代码审查可以直接看到每一条快捷键变更。
- 对 `Ctrl+K` 与 `Ctrl+K,Ctrl+L` 这类序列做前缀分析，区分同一上下文、父子上下文和互斥兄弟上下文。
- 对 `all`、`windows`、`mac`、`linux` 等平台集合进行重叠计算，避免“平台专用快捷键”被全局 fallback 抢走。
- 提供保守的系统/终端/焦点导航保留目录，并保留来源说明；团队可以传入自己的 `ReservedRule` 目录。
- 输出文本、Markdown、JSON、SARIF 2.1.0、冲突图、迁移 diff、推荐修复和发布门禁。
- 核心 API 是纯函数式的：分析不会修改调用者持有的数组，结果对相同输入稳定，可用于离线 CI 和 wasm。

## 当前边界

VS Code profile 只覆盖给定规则快照、显式布尔状态和受支持键名。
未知 when 操作符、缺少必要状态、删除/禁用规则、命令参数、系统级快捷键、扫描码或未覆盖布局等不会被简化成安全结果；
相关探针返回 inconclusive，退出 2。只测试列出的状态，不是遍历真实编辑器所有状态的证明。
原有 DSL 与 dispatcher 是库自定义模型，不能被当作 VS Code 宿主语义。
不自动扫描用户配置、不监听键盘、不自动修复或写回文件。

## 环境

- 本轮完整验证使用 MoonBit `moonc 0.10.12+1634b282e`、`moon 0.1.20260904` 及配套标准库。
- 格式化请使用同一版工具链：0.10.10 与 0.10.12 的结构体尾逗号规则不同。升级编译器时必须同时更新标准库；可使用官方 `moon upgrade`。CI 会输出实际版本，不能用旧版本的本地通过代替最新远程结果。
- DSL 核心和 CLI 策略层只导入 core；模块锁定 `moonbitlang/x@0.5.4`，供文件 IO、正常退出及 vscode profile 的 JSON5/JSONC 读取使用。依赖与宿主接口来源见 THIRD_PARTY_NOTICES。
- 文件 CLI 的 wasm / wasm-gc 版本依赖配套 moonrun 的宿主 IO 接口，不声称可在任意 WASI 运行时运行；JS 版本使用 Node.js。

## 快速开始

```bash
git clone https://github.com/zhangbowen2006/MoonKeyguard.git
cd MoonKeyguard
moon update
moon check --deny-warn
moon test --deny-warn
moon run cmd/main
```

CLI 格式和附加报告：

```bash
moon run cmd/main -- --format json
moon run cmd/main -- --format markdown --suggest
moon run cmd/main -- --format sarif --fail-on-warning
moon run cmd/main -- --metrics
moon run cmd/main -- --source "bind save command=save keys=Ctrl+S" --name quick-demo
moon run cmd/main -- --input examples/editor.keymap --format json --fail-on-error
```

`--input PATH` 只读指定的 UTF-8 配置文件，不自动发现文件或修改原配置；
`--source TEXT` 支持短文本，显式空字符串表示空配置，不再回退到 demo。
参数拼写错误、缺少值、重复参数及同时使用两种输入会被拒绝。
退出码：`0` 完成或门禁通过、`1` 策略门禁失败、`2` 参数/文件/编码/DSL 输入错误；
默认只出报告，`--fail-on-error` 或 `--fail-on-warning` 开启相应门禁。
输入错误无论是否开启门禁都返回 2，不再通过 abort 制造崩溃堆栈。

`--format json` 始终输出一个 JSON 文档：
`schema_version`、`ok`（本次门禁是否通过）、`exit_code`、`analysis`、
`metrics`、`suggestions`、`baseline`。报告模式下要检查风险，请读取
`analysis.errors/warnings/ok`，不要把顶层 `ok` 当作“零风险”。
错误文档含 `error`；人类诊断写 stderr，JSON/SARIF 写 stdout。
参数解析阶段失败时格式选项尚未确立，直接输出 stderr；不会假装已经生成 JSON。
SARIF 不支持附加 metrics/suggest/baseline，避免混入不符合格式的内容。
这是未发布的 CLI 输出结构变化；核心库的 `analysis_to_json` API 不变。

文件先完整读入，再检查 2 MiB 字节限制及 1048576 UTF-16 码元限制。
解析后、成对分析前检查每份配置的绑定数量，默认 2000；
`--max-bindings` 可设为 1..10000。不是流式读取，也不是对抗恶意输入的内存沙箱。
完整“插件冲突—拦截—修复”步骤见 [文件审查示例](examples/review/README.md)。

## DSL 示例

```text
keymap name=editor version=1
context global parent= rank=0 description=all-windows
context editor parent=global rank=10 description=text-editor
reserve Cmd+Q platform=mac
bind save command=editor.save keys=Ctrl+S context=editor platform=all priority=10 description=save-buffer
bind jump_line command=editor.jump_line keys=Ctrl+K,Ctrl+L context=editor platform=all priority=5 description=jump-line
```

`keys` 使用 `+` 表示一个 chord，使用逗号表示连续 chord。`context` 未填写时为 `global`；`platform` 未填写时为 `all`；`priority` 越高，dispatcher 越优先选择。字段值使用无空格的 token，描述可以使用短横线或下划线。

## MoonBit API

在自己的 MoonBit 模块中安装已发布的版本：

```bash
moon add zhangbowen2006/moonkeyguard@0.2.0
```

在调用方的 `moon.pkg` 中添加导入：

```text
import {
  "zhangbowen2006/moonkeyguard" @moonkeyguard,
}
```

```moonbit
let parsed = @moonkeyguard.parse_keymap(source, name="editor")
if !parsed.ok {
  println(@moonkeyguard.parse_diagnostics_to_json(parsed.diagnostics))
}
let analysis = @moonkeyguard.analyze(parsed.keymap)
println(@moonkeyguard.analysis_to_markdown(analysis))
let suggestions = @moonkeyguard.suggest_all(parsed.keymap, analysis)
println(@moonkeyguard.suggestions_to_markdown(suggestions))
```

主要入口：

| API | 用途 |
| --- | --- |
| `parse_keys` / `canonical_keys` | 解析并规范化快捷键序列 |
| `parse_keymap` | 解析 DSL，返回结构化 parser diagnostics |
| `analyze` / `audit` | 运行冲突、上下文、平台、保留键和可访问性规则 |
| `suggest_for` / `suggest_all` | 生成不占用保留键的替换建议 |
| `analysis_to_text/json/markdown/sarif` | 生成终端、文档、机器和 GitHub 代码扫描报告 |
| `build_conflict_graph` | 计算冲突边、连通分量和 hotspot |
| `diff_keymaps` / `migration_plan` | 对两个版本做按 id 的语义 diff |
| `reachability_matrix` / `reachability_to_*` | 按 context/platform 证明绑定可达、遮蔽和不可用状态 |
| `compare_baseline` / `baseline_report_to_*` | 只阻止新增风险，保留历史问题作为可追踪债务 |
| `import_csv` / `import_tsv` / `import_pipe` | 导入常见表格或管道格式 |
| `dispatch` / `replay` | 在纯 MoonBit 模拟器中检查解析结果的可达性 |
| `audit_with_profile` | 应用 desktop、terminal、accessible 或自定义策略 |
| `release_gate` | 汇总结构校验、冲突分析、策略、基准和迁移证据 |

## Reachability matrix

冲突分析回答“声明是否可能重叠”，而可达性矩阵回答“在真实的 context/platform 组合中谁会被 dispatcher 选中”。

```moonbit
let report = @moonkeyguard.reachability_matrix(
  parsed.keymap,
  contexts=["global", "editor"],
  platforms=["all", "mac"],
)
println(@moonkeyguard.reachability_to_markdown(report))
```

探针数组为空时自动使用 keymap 中声明的 context 和 `all` 平台；输入会去重、规范化并排序，适合把 JSON 结果作为 CI artifact。子 context 的绑定不会反向泄漏到父 context。

## Baseline regression gate

Teams that already have accepted findings can ratchet quality without hiding
old debt. Compare two deterministic analyses and fail only when a new error is
introduced:

```moonbit
let baseline = @moonkeyguard.analyze(@moonkeyguard.parse_keymap(old_source).keymap)
let current = @moonkeyguard.analyze(@moonkeyguard.parse_keymap(new_source).keymap)
let report = @moonkeyguard.compare_baseline(baseline, current)
println(@moonkeyguard.baseline_report_to_markdown(report))
```

Finding identities omit source line numbers, so moving a declaration does not
create a false regression. Set `fail_on_warning=true` when warnings are also
blocking for a release.

## 可运行示例

```bash
moon run examples/basic
moon run examples/baseline
```

示例会解析一个 editor/terminal keymap，输出冲突摘要、冲突图热点、dispatcher 回放和建议修复。`examples/basic/main.mbt` 只依赖公开 API，可以直接复制为集成测试的起点。

## 报告与 CI

仓库中的 `.github/workflows/ci.yml` 会在 push、pull request 和手动触发时执行：

```text
moon check --deny-warn
moon build
moon test --deny-warn
moon fmt --check
moon info
```

同时运行 CLI、basic example，并检查 `pkg.generated.mbti` 没有未提交变化。SARIF 输出可以作为 GitHub Code Scanning 的上传输入；项目本身不上传任何键盘记录或用户数据。

## 测试

当前测试覆盖：

- 修饰键别名、非法 chord、空输入和连续 chord；
- parser 的未知 directive、重复 context、保留键和禁用记录；
- 精确冲突、同命令重复、前缀冲突、父子/兄弟 context 和平台集合；
- reserved catalog、Accessibility 风险、策略 profile 和自定义项目规则；
- CSV/TSV/pipe 适配、DSL round-trip、keymap merge 和语义 diff；
- conflict graph、dispatcher/replay、audit timeline、release gate 和 benchmark；
- text/Markdown/JSON/SARIF/schema 输出的稳定字段。

本地运行：

```bash
moon test --deny-warn
```

## 性能与可扩展性

当前实现优先保证可解释性和 wasm 可移植性：解析约为 `O(lines × attributes)`，分析约为 `O(bindings² + bindings × context-depth)`，dispatcher 约为 `O(bindings × context-depth)`。`complexity_report` 和 `run_benchmark` 用于把规模、回归和未来索引优化记录在版本历史中。项目边界明确保留了操作系统 hook 和 GUI 录制功能，避免把静态分析器扩成不可维护的桌面框架。

## 许可证与来源

源代码采用 Apache-2.0，见 [LICENSE](LICENSE)。运行时没有复制第三方实现；仅使用 MoonBit 官方 `moonbitlang/core`。保留快捷键目录中的平台说明和来源链接是政策解释材料，不是从平台代码中移植的实现。更完整的来源记录见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## AI 使用说明

开发过程中使用 AI 辅助生成了部分初稿、测试用例和文档草稿，所有内容均由项目维护者在本地 MoonBit 工具链中审阅、修改并通过测试。没有引入来源不明的代码、素材、用户数据或未授权模型输出；AI 不替代许可证审查、测试和发布决定。详见 [AI_USAGE.md](AI_USAGE.md)。

## 维护与发布

- 变更应保持一个有意义的提交一个主题，保留真实 Git 提交、Issue、PR、测试和发布记录。
- 发布前运行 `moon package --list`，确认包中没有 `_build`、临时文件或敏感数据。
- `0.2.0` 已发布至 [Mooncakes](https://mooncakes.io/docs/zhangbowen2006/moonkeyguard)；2026-09-14 复核 manifest 的 `build_status=success`、`has_package=true`。后续仓库的格式/CI/文档修复不等于重新发布同版本。
- 发布流程、验收证据和风险记录见 `docs/` 与 `submission/`。

## 查重结论（截至 2026-09-13）

已检索 GitHub 近期 MoonBit 仓库和 Mooncakes API。`moonedit`、`proton_global_hotkey` 等提供运行时编辑器/桌面按键支持；它们不提供静态 keymap 冲突图、context 继承分析、保留键策略、SARIF/迁移门禁组合。查重范围、检索关键词、排除项和独立价值记录在 [docs/DEDUPLICATION.md](docs/DEDUPLICATION.md)。这不是“改名避重”：MoonKeyguard 的核心数据模型、规则和测试均为本项目重新设计。
