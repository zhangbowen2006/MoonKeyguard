# MoonKeyguard｜VS Code 扩展快捷键行为回归检查

申请人：张博文｜GitHub：zhangbowen2006｜2026 年 9 月黑客松新项目赛道
项目仓库：https://github.com/zhangbowen2006/MoonKeyguard
Mooncakes：https://mooncakes.io/docs/zhangbowen2006/moonkeyguard
MoonBit 模块：`zhangbowen2006/moonkeyguard`｜许可证：Apache-2.0

## 用途与目标用户

MoonKeyguard 面向维护 VS Code 扩展和键位包的开发者。扩展调整 `contributes.keybindings` 的 `when` 条件或平台键位后，原本约定的“普通编辑执行保存、显式模式触发扩展、只读和非编辑焦点不误触发”可能发生回归。项目把相关规则快照和明确的状态、预期命令写成可在 CI 重放的行为契约，报告实际选中规则、条件判定轨迹和预期差异。

## 现有方案与独立价值

VS Code 已提供同键查看、Keyboard Shortcuts Troubleshooting 和实机测试；这些工具适合检查当前安装与真实键盘事件。本项目补充发布前的离线回归流程：对提交的配置快照批量检查指定状态，输出可留档的机器报告，并在语义不足时返回 `inconclusive`。纯 MoonBit 内核同时供文件 CLI 和直接调用编译后 JS 的 Node 程序使用，二者共用一份解析、判定和报告逻辑。少量个人键位可直接使用 VS Code 内置工具。

## 已实现内容与可复现演示

项目读取调用者提供的相关默认规则、扩展 `package.json`、用户覆盖 JSONC 和场景契约；支持已记录范围内的平台覆盖、布尔 `when`、后置规则优先、命令期望及解释轨迹。仓库的原创开发扩展样例保留相同的 Ctrl+S 键位，只把 `when` 放宽作为故障注入：反例在三个指定状态下回归，修复配置在五个指定状态下通过。运行步骤：

```sh
moon run cmd/main -- vscode --defaults examples/vscode-review/defaults.jsonc --extension examples/vscode-review/extension/package.regression.json --overrides examples/vscode-review/overrides.jsonc --scenarios examples/vscode-review/scenarios.json --platform windows
```

把 `--extension` 的文件改成同目录 `package.json` 即可复验修复结果；完整说明见 `examples/vscode-review/README.md`。样例是原创故障注入，不是线上事故、真实客户数据或 VS Code 实机测试。

## 功能边界与验收证据

仅检查给定的有序规则快照和列出的状态；调用者须提供完整相关规则。未支持的条件操作符、缺少必要状态、禁用规则、命令参数、真实键盘布局、扫描码、焦点变化及第三方扩展注册顺序不会被判定为安全。项目不监听键盘、不修改用户配置，也不替代目标 VS Code 版本的实机核对。

核心实现、解析和行为比较使用 MoonBit；Node.js 只承担文件、进程和直接调用编译结果的宿主边界。仓库提供 README、可运行示例、测试、GitHub Actions、Apache-2.0 许可证、第三方来源和 AI 使用说明。`0.3.1` 已发布至 Mooncakes；对应提交的 CI 记录：https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35838483070 。发布和测试证据见 `docs/PUBLISHING.md`、`docs/TESTING.md`。

## 后续维护

优先补充目标 VS Code 版本的手工实机日志、真实维护者反馈和更多有来源的配置样例，再据证据扩展宿主语义。本项目与申请人的八月项目 MoonBVHKit 在仓库、用途和核心实现上独立；不以代码量、绝对首创或获奖承诺代替项目价值论证。
