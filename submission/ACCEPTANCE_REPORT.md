# MoonKeyguard 复审证据入口

2026-09-29 新增：初审邮件指出申报书、仓库和主题不一致。曾被忽略的旧报名版申报书
已经改写并纳入版本管理；新的一致性检查已接入 CI。应在报名平台用
[`MoonKeyguard_9月黑客松申报书_报名版.md`](MoonKeyguard_9月黑客松申报书_报名版.md)
替换原申报书，并将本次改动推送到公开默认分支。报名平台是否已更新仍待用户确认。

申请人：张博文｜此前发布核验：2026-09-23；0.3.1 已发布，旧 CI 已成功。
2026-09-29 的申报书一致性修复仍需推送及新的远程 CI。

九月第二次初审指出用途、现有方案不足和独立库必要性论证不充分。
本轮不再用代码规模作为主要答案，而是提供具体宿主配置契约和可复用调用端。

- [申报书](../docs/PROJECT_PROPOSAL.md)：目标用户、具体问题、补充价值、边界与维护计划。
- [逐项整改](RESUBMISSION_NOTE.md)：对照本次反馈的实质修改和仍未完成的事项。
- [用途与独立价值](../docs/USE_CASE_AND_VALUE.md)：承认内置工具能力，并说明为什么目前拆出纯内核。
- [宿主 profile](../docs/HOST_PROFILE.md)：布尔条件、顺序、平台选择、inconclusive 与不支持项。
- [可运行案例](../examples/vscode-review/README.md)：原生扩展贡献/处理器、反例和修复、两种调用端。
- [公开提交与新 CI](../docs/REMOTE_REVIEW_20260922.md)：提交、真实失败修复、新工具链结果及未验证边界。
- [前序本地记录](../docs/LOCAL_REVIEW_20260917.md)：保留推送前的历史状态。
- [差距表](../docs/ACCEPTANCE_GAP.md)与[最后清单](FINAL_CHECKLIST.md)。

提交 `c3dd6f2` 的 [最终发布提交 CI](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35838483070)
是本轮远程工程证据；[Mooncakes 0.3.1](https://mooncakes.io/docs/zhangbowen2006/moonkeyguard)
已正式发布，公开 manifest 显示构建成功且包可用。组委会尚未批准本轮初审，不能提前标为通过。
