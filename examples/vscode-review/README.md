# VS Code 扩展 when 条件回归：完整复现

本地 Unreleased 示例，不是客户采用案例、公开插件或真实事故。
extension/package.json 是可加载的开发扩展；package.regression.json 是刻意注入错误的测试变体。
defaults 文件只是相关保存规则的手工声明快照，并非某个 VS Code 版本的完整默认键位导出。
用于实际项目时，请更换为目标安装的相关有序规则和自己的场景契约。

## 先运行离线检查

```sh
moon run cmd/main -- vscode --defaults examples/vscode-review/defaults.jsonc --extension examples/vscode-review/extension/package.regression.json --overrides examples/vscode-review/overrides.jsonc --scenarios examples/vscode-review/scenarios.json --platform windows
```

反例退出1：普通编辑、有选区但未开启 wrapMode、只读状态共三个回归。
把 extension 文件改为 extension/package.json，五个状态全部通过，退出0。
mac 平台使用 defaults.mac.jsonc 并设置 --platform mac；Linux 使用 defaults.jsonc。
场景文件显式包含 mac 键位，不从当前测试机器推断。

## 直接复用编译后 JS 库

```sh
moon build --target js --release
node scripts/check_vscode.mjs examples/vscode-review/defaults.jsonc examples/vscode-review/extension/package.json examples/vscode-review/overrides.jsonc examples/vscode-review/scenarios.json windows
node scripts/test_vscode.mjs
```

JS 调用者直接导入 audit_json，和 MoonBit CLI 共用同一纯内核。
自动化验证六组 fixture/platform，做12次调用端结果比较；报告保存在 _build/host-evidence。
另有使用最小 mock host 的扩展处理器测试，确认显式开启模式后会包裹选区。
这些都不是实际 VS Code 键盘事件测试。

## 人工宿主核对（待执行，不得预先标为通过）

1. 用 VS Code 打开 examples/vscode-review/extension 文件夹，按 F5 启动单独开发宿主。
   launch 配置使用该目录下的 .dev-profile，不改系统用户配置。
2. 在临时可写文件选中文字，通过命令面板运行 Keyguard Demo: Toggle Wrap Mode。
3. 在模式关闭/开启时分别按 Ctrl+S（mac 为 Cmd+S），记录实际执行命令。
4. 使用 Developer: Toggle Keyboard Shortcuts Troubleshooting 收集宿主日志，
   再核对普通焦点、无选区、只读状态及用户覆盖。不要把未经实测的 defaults 当成编辑器真实规则。
5. 记录 VS Code 版本、平台、布局、扩展清单及日志，说明与离线输入是否一致。
   若实际规则顺序或条件不在 profile 范围，报告为未覆盖，而不是宣称宿主错误。

为安全起见，不建议把故障注入变体装入日常工作配置。当前只提供手工核对步骤，
没有声称上述五步已执行。完整限制见 ../../docs/HOST_PROFILE.md。
