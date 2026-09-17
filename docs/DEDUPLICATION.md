# 相似方案与独立价值核对

日期：2026-09-17。该记录不再以“未发现同功能组合”作为独特性的充分证明。

## 本轮实际检索

查询 Mooncakes API（每个关键词最多10条）：vscode、keybinding、shortcut。
同时搜索 GitHub/Mooncakes 中 MoonBit、VS Code keybindings regression/contract 相关结果。
返回了模糊匹配、命令注册、终端输入等项目，以及 MoonKeyguard 自身的0.2.0描述。
本轮未逐一审阅整个生态全部代码，不能宣称排除了所有相似实现；历史广泛查重说法不作为本轮验收保证。

## 必须承认的现有能力

VS Code 自带 Show Same Keybindings 和 Keyboard Shortcuts Troubleshooting，
也有真实宿主测试与可编写的项目脚本。这些方案已经解决“有没有同键”“按下后实际执行什么”等问题。
官方还解释了扩展默认规则覆盖与键盘布局的复杂性：
[键盘文档](https://code.visualstudio.com/docs/configure/keybindings)、
[官方排障说明](https://github.com/microsoft/vscode/wiki/Keybinding-Issues)。

## 本项目收窄后的贡献

不是重做所有宿主输入路由，也不是给已有项目改名或做简单 CLI 包装。
本轮新增的是原创 MoonBit 的限定布尔条件解析、顺序规则判定、指定状态契约对照、未知语义处理与轨迹报告，
并由 wasm 文件 CLI 和直接编译到 JS 的调用端共用。
目标是让维护者把已约定的状态行为保留成 CI 回归数据，而不是每次只看一张同键列表。

这条贡献是否足以形成独立库价值，仍需要实际使用反馈和组委会判断。
请结合 USE_CASE_AND_VALUE.md 的适用/不适用条件，不对相似项目作未经代码核验的功能否定。

## 与八月项目的关系

MoonBVHKit 是申请人的八月项目；空间几何/BVH 与快捷键宿主契约在用途及核心实现上不同。
本轮保持独立仓库与真实历史，不重建同名项目、不伪造外部贡献、不复用其他选手报名信息。
