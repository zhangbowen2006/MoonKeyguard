# 9 月黑客松验收差距表

核验日期：2026-09-14。区分本地证据、公开证据和组委会结论，不用提交总数代替有效开发。

| 要求 | 当前证据 | 风险或下一步 |
| --- | --- | --- |
| 截图中的赛期开发记录与 MVP | 默认分支已有解析分析、适配策略、基线门禁、CLI 输入/示例、可达性分析五项功能提交，见 `submission/RESUBMISSION_NOTE.md` | 是否认可有效提交和 MVP，由组委会复审决定；格式/重复修复不计作新增功能 |
| MoonBit 主要实现语言及规模 | 28 个根目录生产 .mbt 文件：剔除空行和整行注释 5681 行，再剔除纯分隔符行 4643 行；不含测试、cmd/、examples/ | 此为明确口径的本地计数，不等于评委的有效代码认定 |
| 公开仓库及默认分支 | GitHub API 确认 public、默认分支 main；本轮核对远程为 5c84363 | 格式和脚本修复已在本地提交，但 Git 推送尚缺可用认证 |
| README、API、文档 | README 含安装、快速开始、API、边界、测试、CI 和发布；已修复 API 表格断裂及过期发布说法 | 文档修改随本轮提交同步 |
| 可运行示例 | `moon run examples/basic` 和 `moon run examples/baseline` 均退出 0 | 等待修复提交的远程复跑 |
| 可运行测试与构建 | 配套 MoonBit 0.10.12 上 check/build 成功，89/89 测试通过；非法输入门禁按预期退出 1 | 不将预期负向测试记为项目构建失败 |
| CI | [最近已核验运行](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/34842814155)：check/build/test 成功，Format 失败，后续步骤跳过 | 尚未闭环。用 0.10.12 精确格式化后的代码本地 fmt 通过，需推送并取得新绿色运行 |
| API 与包清单 | `moon info` 后 .mbti 无差异；`moon package --list` 成功，未包含临时克隆或报名版 | CI 诊断日志改放 RUNNER_TEMP，避免混入包 |
| Mooncakes | [manifest](https://mooncakes.io/api/v0/manifest/zhangbowen2006/moonkeyguard) 返回 0.2.0、build_status=success、has_package=true、yanked=false | 已发布包不包含随后仅在仓库进行的工程修复；本轮不重复发布 0.2.0 |
| 开源及维护边界 | Apache-2.0 LICENSE、THIRD_PARTY_NOTICES、AI_USAGE、CHANGELOG、架构与来源记录 | 独立价值不等于全球首创；不承诺获奖 |
| 个人信息隔离 | 公开材料申请人为张博文，Git 作者账户为 zhangbowen2006；公开 Markdown/源码未匹配申请人电话邮箱 | 报名联系方式只填官方表单；提交前继续检查包清单 |

结论：截图提出的缺少开发记录/MVP已有具体整改成果，可供重新审核；不能据此声称初审或最终验收已通过。本地工程检查已通过，仍需完成正常 HTTPS 推送和最新 CI 全绿，再更新报名材料。
