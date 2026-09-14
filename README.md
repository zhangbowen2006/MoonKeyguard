# MoonKeyguard

MoonKeyguard 是一个 MoonBit 原生的键盘快捷键静态分析工具包。它把应用的快捷键声明看作一份可审查的策略文件，在不启动 GUI、不依赖操作系统钩子的情况下，发现快捷键冲突、Chord 前缀歧义、上下文继承遮蔽、平台范围重叠、保留快捷键和键盘可访问性风险，并生成可供 CI、代码审查和发布流程使用的报告。

项目与 8 月项目 MoonBVHKit 完全独立：没有复用 BVH 代码、数据模型或实现范围，也不是拆分、改名或包装旧仓库。MoonKeyguard 的用户是桌面应用、终端工具、编辑器、TUI 和多平台 GUI 的维护者，解决的是“按键声明在合并后是否仍然可达、可发现、可解释”的工程问题。

## 核心价值

- 用轻量 DSL 表达 `bind`、`context`、`reserve` 和 `keymap` 声明，代码审查可以直接看到每一条快捷键变更。
- 对 `Ctrl+K` 与 `Ctrl+K,Ctrl+L` 这类序列做前缀分析，区分同一上下文、父子上下文和互斥兄弟上下文。
- 对 `all`、`windows`、`mac`、`linux` 等平台集合进行重叠计算，避免“平台专用快捷键”被全局 fallback 抢走。
- 提供保守的系统/终端/焦点导航保留目录，并保留来源说明；团队可以传入自己的 `ReservedRule` 目录。
- 输出文本、Markdown、JSON、SARIF 2.1.0、冲突图、迁移 diff、推荐修复和发布门禁。
- 核心 API 是纯函数式的：分析不会修改调用者持有的数组，结果对相同输入稳定，可用于离线 CI 和 wasm。

## 当前边界

MoonKeyguard 是声明分析库和 dispatcher 模拟器，不是操作系统级按键 hook、GUI 按键录制器或窗口管理器。它不读取/修改用户的桌面配置，也不会替应用决定最终的人机交互设计。CLI 默认审计仓库内置的演示 keymap；在应用、脚本或 CI 中通过 `parse_keymap` 传入真实内容。

## 环境

- MoonBit 0.10.10 或更新版本（本地验收使用 `moon 0.1.20260824` / `moonc 0.10.10`）。
- 本项目只使用 `moonbitlang/core`，没有额外运行时依赖。

## 快速开始

```bash
git clone https://github.com/zhangbowen2006/MoonKeyguard.git
cd MoonKeyguard
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
```

`--source` accepts a small inline keymap for shell smoke tests and demos. For
larger files, call `parse_keymap` from MoonBit and pass the resulting keymap to
`analyze`; this keeps file-system policy in the host application. When
`--fail-on-warning` is supplied, the CLI exits with status 1 for any error or
warning so it can be used as a release gate.

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
| `import_csv` / `import_tsv` / `import_pipe` | 导入常见表格或管道格式 |
| `dispatch` / `replay` | 在纯 MoonBit 模拟器中检查解析结果的可达性 |
| `audit_with_profile` | 应用 desktop、terminal、accessible 或自定义策略 |
| `release_gate` | 汇总结构校验、冲突分析、策略、基准和迁移证据 |

## 可运行示例

```bash
moon run examples/basic
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
- 只有真实执行 `moon publish --frozen` 并拿到 Mooncakes 页面后，才在申报材料中填写发布链接；当前仓库尚未声称已发布。
- 发布流程、验收证据和风险记录见 `docs/` 与 `submission/`。

## 查重结论（截至 2026-09-13）

已检索 GitHub 近期 MoonBit 仓库和 Mooncakes API。`moonedit`、`proton_global_hotkey` 等提供运行时编辑器/桌面按键支持；它们不提供静态 keymap 冲突图、context 继承分析、保留键策略、SARIF/迁移门禁组合。查重范围、检索关键词、排除项和独立价值记录在 [docs/DEDUPLICATION.md](docs/DEDUPLICATION.md)。这不是“改名避重”：MoonKeyguard 的核心数据模型、规则和测试均为本项目重新设计。
