# MoonKeyguard 复审证据入口

申请人：张博文｜更新：2026-09-17｜本轮状态：本地整改，未推送、未发布。

九月第二次初审指出用途、现有方案不足和独立库必要性论证不充分。
本轮不再用代码规模作为主要答案，而是提供具体宿主配置契约和可复用调用端。

- [申报书](../docs/PROJECT_PROPOSAL.md)：目标用户、具体问题、补充价值、边界与维护计划。
- [逐项整改](RESUBMISSION_NOTE.md)：对照本次反馈的实质修改和仍未完成的事项。
- [用途与独立价值](../docs/USE_CASE_AND_VALUE.md)：承认内置工具能力，并说明为什么目前拆出纯内核。
- [宿主 profile](../docs/HOST_PROFILE.md)：布尔条件、顺序、平台选择、inconclusive 与不支持项。
- [可运行案例](../examples/vscode-review/README.md)：原生扩展贡献/处理器、反例和修复、两种调用端。
- [本轮本地记录](../docs/LOCAL_REVIEW_20260917.md)：实际测试命令、结果和未验证的实机边界。
- [差距表](../docs/ACCEPTANCE_GAP.md)与[最后清单](FINAL_CHECKLIST.md)。

已发布的 [Mooncakes 0.2.0](https://mooncakes.io/docs/zhangbowen2006/moonkeyguard) 与历史绿色 CI 是旧工程基础，
不是这次新增 profile 的发布或远程验收证据。组委会尚未批准本轮初审，不能提前标为通过。
