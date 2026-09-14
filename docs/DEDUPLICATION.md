# 查重与独立性记录

审查日期：2026-09-14。目标是判断 MoonKeyguard 是否只是 MoonBVHKit、近期参赛项目或已有 Mooncakes 包的改名包装。

## 检索范围

- GitHub MoonBit 仓库搜索：`language:MoonBit created:2026-08-20..2026-09-13`，抽查近期约 239 个结果及其 README/包描述。
- Mooncakes API：`https://mooncakes.io/api/v0/search?kw=<keyword>&limit=20`。
- 关键词：`keybinding`、`keyboard shortcut`、`shortcut conflict`、`keymap`、`hotkey`、`accessibility`、`conflict graph`、`SARIF`、`chord parser`。

## 相近但不同的项目

| 项目/方向 | 已有能力 | MoonKeyguard 的独立边界 |
| --- | --- | --- |
| `vectie/moonedit` | 编辑器运行时 keybinding/编辑器功能 | 不提供静态 keymap 冲突图、context 继承和 CI 门禁 |
| `moonbit-community/proton_global_hotkey` | 桌面全局热键绑定 | 不安装 OS hook，不捕获用户按键，专注离线声明分析 |
| `wzzc-dev/moui`、窗口/GUI 项目 | GUI 输入路由和组件 | 不做 GUI 框架、渲染、焦点运行时 |
| `Jay7724/paletteguard`、`palette_forge` | 颜色/调色板可访问性 | 不分析视觉 token 或颜色，只分析键盘声明和交互边界 |
| `moonverity`、`moon-stream-quality` | CSV/JSONL 数据质量 | CSV 在本项目只是 keymap 适配输入，不做通用数据契约 |
| `moonchange`、`moondiff` | 仓库/文本变更治理 | 本项目的 diff 针对快捷键语义：命令、context、platform、dispatcher 风险 |
| 运行时 hotkey/输入路由库 | 负责注册或分发按键 | 本项目新增方向性可达性矩阵，证明声明在具体 context/platform 中的实际赢家 |

## 独立价值结论

未发现一个同时提供“快捷键 DSL + 父子 context 重叠 + chord 前缀 + 平台保留键 + 冲突图 + SARIF + 可达性矩阵 + 迁移门禁”的 MoonBit 项目。MoonKeyguard 也不是对上述项目的移植：生产代码、结构体、规则和 89 个测试均为本仓库重新实现。

该结论不是永久保证。提交前应重新搜索 GitHub 和 Mooncakes；若出现功能重合，应在 Issue/设计说明中缩小边界或明确互操作关系，而不是只改项目名。
