# MoonKeyguard 9 月黑客松项目申报书

## 项目与用户

MoonKeyguard 面向桌面应用、终端工具、编辑器、TUI 和多平台 GUI 的维护者。项目以 MoonBit 为核心实现语言，提供一个可嵌入库和可运行 CLI，用于在发布前审查快捷键声明。

## 痛点与方案

快捷键通常散落在 GUI、终端和插件配置中，合并后容易出现重复、前缀遮蔽、平台误用和不可发现的单键操作。现有运行时输入库只能“绑定”，无法在代码审查阶段解释“为什么某个命令不可达”。MoonKeyguard 用显式 DSL、context 继承和平台集合运算把这类问题转化为可复现的静态报告。

## 预期功能

- 规范化 modifier 和连续 chord；
- 精确冲突、前缀冲突、shadowing、reserved key、可访问性与结构校验；
- conflict graph、dispatcher replay、CSV/TSV/pipe adapter；
- 自定义 profile、reservation catalog、项目规则、语义 diff 和 release gate；
- Text/Markdown/JSON/SARIF/schema 输出以及可运行示例。

## 技术路线与边界

项目只依赖 MoonBit core，核心 API 为纯函数，可编译到 wasm。当前分析复杂度为 `O(bindings² + bindings × context-depth)`，以清晰的诊断和审查证据优先。OS hook、GUI 按键录制、云同步和用户数据采集明确不在范围内。

## 测试与工程化

81 个测试覆盖核心路径、错误路径、边界输入、适配器、dispatcher 和发布门禁；CI 执行 check/build/test/fmt/info；根目录提供 Apache-2.0、CHANGELOG、第三方来源和 AI 使用说明。

## 独立性

项目与 8 月 MoonBVHKit 完全不同。查重记录见 `docs/DEDUPLICATION.md`，当前未发现同一功能组合的 MoonBit 参赛项目。
