# 9 月黑客松验收差距表

该表只记录当前可验证证据；“待远程确认”不是已完成状态。

| 要求 | 当前证据 | 状态 | 修复/确认动作 |
| --- | --- | --- | --- |
| MoonBit 为主要实现语言 | 生产 MoonBit 源码约 5.3k 行，81 个测试 | 已满足（本地） | 远程 CI 再跑一次 |
| 代码仓库公开可访问 | GitHub public 仓库，默认分支 `main`，最新提交 `bd8681e` | 已满足 | 持续维护 |
| README 清晰完整 | 根 `README.md` | 已满足（本地） | 远程页面检查链接 |
| 用途、功能、使用方法 | README、KEYMAP_FORMAT、PROJECT_PROPOSAL | 已满足 | 无 |
| 可运行示例 | `examples/basic` | 已满足（本地） | CI 固化命令 |
| CI | Actions run `34755575667` success | 已满足 | 后续提交继续保持绿色 |
| 可运行测试 | `moon test --deny-warn`：81 passed | 已满足（本地） | 干净树复跑 |
| 正常构建 | `moon build` PASS | 已满足（本地） | 发布前复跑 |
| Mooncakes 发布 | manifest 返回 `200`，`0.1.0`、构建成功、包存在 | 已满足 | 后续版本递增发布 |
| 提交记录可追踪 | GitHub `main` 已包含 6 个有意义提交 | 已满足 | 继续保留真实提交 |
| 功能边界与维护价值 | ARCHITECTURE、CHANGELOG、Issue/PR 约定 | 已满足（本地） | 建仓后继续维护 |
| 开源许可证 | Apache-2.0 `LICENSE` | 已满足 | 复核 Mooncakes 元数据 |
| 查重独立性 | DEDUPLICATION 记录 GitHub/Mooncakes 检索 | 初步满足 | 报名前重新检索并更新日期 |

公开仓库、远程 CI 和 Mooncakes 发布均已有真实链接与接口证据；仍需按赛事平台要求提交报名材料并在验收前复查。
