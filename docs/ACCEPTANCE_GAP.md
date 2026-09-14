# 9 月黑客松验收差距表

审查日期：2026-09-14。表格只记录当前可验证证据；远程未同步的本地提交不视为已完成。

| 要求 | 当前证据 | 状态 | 风险/下一步 |
| --- | --- | --- | --- |
| MoonBit 为主要实现语言 | 生产 MoonBit 源码约 6.1k 行；`moon.mod`；89 个可运行测试 | 已满足（本地） | 推送后等待远程 CI |
| 代码仓库公开可访问 | GitHub public 仓库 `zhangbowen2006/MoonKeyguard`；远程默认分支 `main` | 已满足 | 当前网络无法完成本轮推送，需在 GitHub Desktop 点击 Push origin |
| 最新提交位于默认分支 | 本地 `main` 最新 `352a238`；`origin/main` 仍为 `267c605` | 待同步 | 推送 `main` 后再次核对 |
| README 清晰完整 | 根 `README.md` 覆盖用途、安装、API、边界、示例、测试、CI 和发布 | 已满足（本地） | 推送后检查 GitHub 渲染 |
| 用途、功能、使用方法 | README、`docs/KEYMAP_FORMAT.md`、`docs/PROJECT_PROPOSAL.md` | 已满足 | 无 |
| 可运行示例 | `examples/basic`、`examples/baseline`；本地 `moon run` 通过 | 已满足（本地） | 远程 CI 复跑 |
| CI | 已有历史绿色 Actions；本轮工作流配置包含 check/build/test/fmt/info/package/示例 | 部分满足 | 推送后保存新提交的绿色 run 链接 |
| 可运行测试 | `moon test --deny-warn`：89/89 通过 | 已满足（本地） | 推送后等待 CI |
| 正常构建 | `moon build` 通过 | 已满足（本地） | 发布前干净树复跑 |
| Mooncakes 发布 | `moon publish --frozen` 实际退出码 0，终端返回 `Server status: 200 OK`；包版本 `0.2.0` | 已满足 | 页面：[Mooncakes 文档](https://mooncakes.io/docs/zhangbowen2006/moonkeyguard) |
| 提交记录可追踪 | 本地新增真实提交 `352a238`（功能提交为 `371d13e`），包含可达性矩阵和方向性 dispatcher 修复 | 部分满足 | 推送后在 GitHub 公开该提交 |
| 功能边界与维护价值 | `docs/ARCHITECTURE.md`、`docs/DEDUPLICATION.md`、CHANGELOG 和申报书 | 已满足 | 持续维护真实 Issue/PR |
| 开源许可证 | 根目录 Apache-2.0 `LICENSE` | 已满足 | 无 |
| 查重独立性 | `docs/DEDUPLICATION.md` 记录 GitHub/Mooncakes 关键词检索；新增可达性矩阵属于独立静态审查能力 | 初步满足 | 报名前重新检索，不能承诺绝对无相似项目 |
| 个人信息隔离 | 手机号/邮箱只在被 `.gitignore` 排除的报名版文件中；公开材料仅保留申请人姓名 | 已满足（本地） | `moon package --list` 已确认未打包报名版 |

结论：本地工程和 0.2.0 Mooncakes 包已达到提交前状态；唯一未闭环项是把本地 `main` 的真实提交推送到 GitHub 并取得新 CI 绿色记录。