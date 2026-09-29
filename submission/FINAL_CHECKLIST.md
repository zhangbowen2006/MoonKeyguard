# MoonKeyguard：9 月 30 日前报名与验收检查清单

官方九月赛页面写明 **2026 年 9 月 30 日截止报名与验收**：
https://moonbitlang.github.io/Hackathon2026/
本清单更新于 2026-09-29。最终以组委会后续通知和报名系统显示为准。

## 本次驳回的直接原因

2026-09-29 初审邮件指出：申报书与实际提交的 GitHub 仓库、项目主题不一致。
本地 `submission/MoonKeyguard_9月黑客松申报书_报名版.md` 曾被 `.gitignore` 排除，
内容还是“通用桌面/终端快捷键静态分析”和 0.2.0 旧证据，与公开仓库当前
“VS Code 扩展快捷键行为回归检查”主题不一致。该文件已经改写并纳入 Git，
CI 新增与 `docs/PROJECT_PROPOSAL.md`、`moon.mod` 的一致性检查。
**修正本地文件不会自动修改已经提交的线上报名表。**

## 报名表中逐项核对

- [ ] 项目名称：`MoonKeyguard`。
- [ ] 项目仓库：`https://github.com/zhangbowen2006/MoonKeyguard`。
- [ ] 项目主题：`VS Code 扩展快捷键行为回归检查`。
- [x] GitHub 仓库右侧 About 简介已更新为 `MoonBit library for CI regression checks of VS Code extension keybinding behavior contracts.`，并通过 GitHub API 核验，与申报主题一致。
- [ ] 申报书：复制或上传本目录 `MoonKeyguard_9月黑客松申报书_报名版.md` 的最新完整内容；不要再使用旧缓存文件或 MoonBit Target Parity 申报书。
- [ ] 赛道：九月新项目赛道；八月 MoonBVHKit 是独立项目，不将其成果混入本项目。
- [ ] 姓名及联系方式：只在报名平台核对申请人本人信息；公开仓库不提交手机号和邮箱。
- [ ] 如修改表单时推荐人字段不能留空，按此前赛事提醒填写“无”或其他非空内容。
- [ ] 保存并重新提交报名表；留存平台显示的成功页面或通知。只有组委会再次审核后才能称为通过初审。

## 仓库与验收证据

- [x] MoonBit 核心、清晰 README、可运行 VS Code 配置反例/修复示例、测试和 CI 已存在于仓库。
- [x] Apache-2.0、第三方来源、AI 使用说明、设计与发布记录已存在。
- [x] Mooncakes 0.3.1 发布记录及对应旧提交的绿色 CI 已留档。
- [x] 此次申报书及检查脚本已随提交 `0cb34d1` 推送到公开默认分支。
- [x] 该提交的 [GitHub Actions](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/36530532486) 已全部成功，包括新的一致性检查。
- [ ] 如组委会要求实机证据，在目标 VS Code 版本按 `examples/vscode-review/README.md` 操作并留真实日志。目前尚无实机键盘测试或外部维护者使用反馈。

本清单不保证选题获批或获奖；初审结果及赛道资格由组委会确认。
