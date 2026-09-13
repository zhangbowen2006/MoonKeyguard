# MoonKeyguard：2026 MoonBit 9 月黑客松项目申报书

## 一、项目基本信息

- 项目名称：MoonKeyguard
- 参赛方向：新项目赛道；与 8 月项目 MoonBVHKit 完全独立
- GitHub：[zhangbowen2006/MoonKeyguard](https://github.com/zhangbowen2006/MoonKeyguard)
- Mooncakes：[zhangbowen2006/moonkeyguard@0.1.0](https://mooncakes.io/docs/zhangbowen2006/moonkeyguard)
- 许可证：Apache-2.0

## 二、项目背景与目标

桌面应用、终端工具、编辑器、TUI 和多平台 GUI 的快捷键，往往分散在
配置文件、插件和代码中。它们在合并后可能产生重复绑定、Chord 前缀遮蔽、
父子上下文误覆盖、平台专用键误用、系统保留键冲突和不可发现的单键操作。
现有运行时输入库通常负责“绑定”，却难以在代码审查和发布前回答“哪个命令
不可达、为什么冲突、如何修复”。

MoonKeyguard 的目标是提供一个 MoonBit 原生、可嵌入、可离线运行的快捷键
静态分析工具，把快捷键声明转换为可解释的诊断、迁移建议和 CI 发布门禁。

## 三、核心功能与用户

项目用户是需要维护快捷键体系的应用开发者、编辑器作者、插件作者和 CI
维护者。核心能力包括：

- 用轻量 DSL 表达 `keymap`、`context`、`reserve` 和 `bind`；
- 规范化 modifier 与连续 Chord，识别精确冲突、前缀冲突和 shadowing；
- 分析父子 context 继承、兄弟 context 隔离和平台集合重叠；
- 检查系统/终端/焦点导航保留键及键盘可访问性风险；
- 输出冲突图、语义 diff、迁移建议、dispatcher replay 和 release gate；
- 支持 Text、Markdown、JSON、SARIF 2.1.0、schema、CSV/TSV/pipe 适配；
- 提供纯函数 API、CLI 和可直接运行的 `examples/basic` 示例。

## 四、创新点与独立价值

MoonKeyguard 的独立价值不是重新实现一个按键运行时，而是把“快捷键可达性
和交互边界”纳入静态审查：同一个分析模型同时处理 Chord 前缀、上下文继承、
平台范围、保留键、可访问性、冲突图和发布门禁。这样，快捷键变更可以像代码
一样进入 CI，并能输出面向开发者和代码扫描平台的解释性证据。

截至 2026-09-13，已对 GitHub 与 Mooncakes 使用 `keymap`、`keybinding`、
`shortcut conflict`、`hotkey`、`accessibility`、`SARIF` 等关键词进行初步查重，
未发现同时覆盖上述功能组合的 MoonBit 项目。该结论是带日期的初步审查，不能
承诺永久没有相近项目；项目将持续维护查重记录并明确功能边界。

## 五、技术路线与边界

项目以 MoonBit 为主要实现语言，仅依赖 `moonbitlang/core`。解析器将 DSL
转换为结构化 keymap，规则引擎通过规范化快捷键、context 祖先关系和平台集合
运算生成诊断；冲突图和建议器复用同一分析结果。核心分析复杂度约为
`O(bindings² + bindings × context-depth)`，优先保证结果稳定、可解释和可测试，
并支持 wasm 目标。

项目明确不包含操作系统级按键 hook、GUI 按键录制、云同步、用户数据采集、
窗口管理和替应用决定最终交互设计。CLI 默认分析内置演示 keymap，真实应用
通过 API 或脚本传入声明内容。

## 六、工程化与验收证据

- 生产 MoonBit 代码约 5k 行，测试覆盖 81 个用例；
- 本地已通过 `moon check --deny-warn`、`moon build`、`moon test --deny-warn`、
  `moon fmt --check`、`moon info` 和 `moon package --list`；
- GitHub Actions 已在提交 `bd8681e` 上成功完成 check、build、test、fmt、info、
  package 和示例 smoke test；
- 已执行 `moon publish --frozen`，Mooncakes manifest 返回 200，版本为
  `0.1.0`，构建状态为 success；
- 根目录提供 README、Apache-2.0 LICENSE、CHANGELOG、第三方来源说明、AI 使用
  说明、设计文档、测试记录、发布清单和验收差距表；
- 所有实现、测试 fixture 和示例均为本项目重新编写，没有复制来源不明的代码、
  素材或其他选手的报名资料。

## 七、后续维护计划

后续版本将优先完善规则目录的可配置性、更多编辑器/终端适配器、诊断稳定性、
性能基准和文档示例，并通过真实 Issue、合并请求、测试记录、CHANGELOG 和版本
发布持续维护。每次规则变化都会同步更新测试、schema、示例和迁移说明。

## 八、申报承诺

本项目提交的仓库、提交记录、测试结果、CI 状态和 Mooncakes 状态均以公开可验证
证据为准；不伪造用户数量、Issue、PR、下载量或获奖结果。项目作者将按赛事要求
补充报名表中的个人信息，并在提交前复核仓库链接、分支、CI 和发布状态。
