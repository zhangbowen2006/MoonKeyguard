# MoonKeyguard｜2026 MoonBit 9 月黑客松项目申报书
申请人：张博文｜账户：zhangbowen2006｜赛道：新项目｜许可证：Apache-2.0。

项目仓库：[zhangbowen2006/MoonKeyguard](https://github.com/zhangbowen2006/MoonKeyguard)。
已发布模块：[zhangbowen2006/moonkeyguard 0.2.0](https://mooncakes.io/docs/zhangbowen2006/moonkeyguard)。

## 用途与独立价值
面向编辑器、桌面应用、终端/TUI 及插件维护者，在合并快捷键声明后、启动应用之前，分析冲突、遮蔽和命令可达性。
核心定位是可嵌入 CI 的离线静态审查与分派模拟，不是操作系统按键 hook。
相似项目检索见 [查重记录](DEDUPLICATION.md)：暂未发现同等功能组合的 MoonBit 项目，不宣称全球首创或绝对没有相近功能。
本项目与八月参赛项目 MoonBVHKit 的选题、仓库及核心实现独立，不重复申报旧成果。

## 已完成 MVP 与技术方案
以 MoonBit 实现 DSL 解析、快捷键规范化、上下文继承/平台交集规则、冲突图和可解释诊断。
支持精确/前缀冲突、保留键与可访问性风险、语义差异、修改建议、CSV/TSV/pipe 适配及 Text/Markdown/JSON/SARIF 输出。
初审反馈后已新增基线回归门禁、CLI inline 输入、可运行基线示例，以及方向性的 context/platform 可达性矩阵与 dispatcher 修复。
核心为 MoonBit 纯函数 API，仅依赖官方 core；不采集真实键盘数据、不自动修改桌面配置，也不承诺覆盖宿主应用的一切动态行为。
分析器采用规范化序列比较、上下文祖先关系与平台集合运算；当前成对冲突分析具有平方级规模限制。

## 可复现成果与开发记录
`moon run examples/basic` 展示解析、分析、冲突图、回放及可达性；`moon run examples/baseline` 展示新增风险门禁。
28 个根目录生产 MoonBit 文件在剔除空行、整行注释和纯分隔符行后为 4643 行，不含测试、cmd/、examples/；最终有效规模以评委认定为准。
本轮 MoonBit 0.10.12 配套工具链下 check/build/test/fmt/info、包清单和示例通过，89/89 测试；错误输入门禁按预期返回非零。
[五项功能提交与初审整改证据](../submission/RESUBMISSION_NOTE.md)可追踪，不使用空提交、重写历史或格式提交凑功能数量。
Mooncakes manifest 已确认 0.2.0 构建成功；默认分支上的验证提交 `fa7161a` 已通过 [完整 CI（运行 34864976303）](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/34864976303)，包括 check/build/test/fmt/info、打包及全部示例。本材料申请复审，不声称组委会已批准初审或验收。

## 后续维护与申报承诺
继续维护边界/错误路径测试、诊断稳定性、规则来源、适配器与性能基准；README、设计、测试、发布、CHANGELOG 和 AI_USAGE 已提供。
仅使用可说明来源的代码与 fixture，第三方来源与许可证记录见 THIRD_PARTY_NOTICES；不使用其他选手的报名信息。
依照初审通知在 9 月 24 日前更新报名表申请复审；工程完成度、独立价值和获奖由组委会审核，不伪造发布、测试或用户数据。
