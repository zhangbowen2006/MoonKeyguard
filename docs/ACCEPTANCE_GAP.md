# 9 月黑客松验收差距表

该表只记录当前可验证证据；“待远程确认”不是已完成状态。

| 要求 | 当前证据 | 状态 | 修复/确认动作 |
| --- | --- | --- | --- |
| MoonBit 为主要实现语言 | 生产 MoonBit 源码约 5.3k 行，81 个测试 | 已满足（本地） | 远程 CI 再跑一次 |
| 代码仓库公开可访问 | `moon.mod` 已写预期 URL | 待确认 | 创建公开 GitHub 仓库并验证默认分支 |
| README 清晰完整 | 根 `README.md` | 已满足（本地） | 远程页面检查链接 |
| 用途、功能、使用方法 | README、KEYMAP_FORMAT、PROJECT_PROPOSAL | 已满足 | 无 |
| 可运行示例 | `examples/basic` | 已满足（本地） | CI 固化命令 |
| CI | `.github/workflows/ci.yml` | 已配置 | 推送后保存真实 Actions 链接 |
| 可运行测试 | `moon test --deny-warn`：81 passed | 已满足（本地） | 干净树复跑 |
| 正常构建 | `moon build` PASS | 已满足（本地） | 发布前复跑 |
| Mooncakes 发布 | `moon.mod` 已准备；未发布 | 未完成 | 登录后 `moon package --list`、`moon publish --frozen` |
| 提交记录可追踪 | 本地 Git 已初始化，尚未形成远程历史 | 待完成 | 分主题提交并推送，不制造空提交 |
| 功能边界与维护价值 | ARCHITECTURE、CHANGELOG、Issue/PR 约定 | 已满足（本地） | 建仓后继续维护 |
| 开源许可证 | Apache-2.0 `LICENSE` | 已满足 | 复核 Mooncakes 元数据 |
| 查重独立性 | DEDUPLICATION 记录 GitHub/Mooncakes 检索 | 初步满足 | 报名前重新检索并更新日期 |

当前不能声称“已公开仓库”或“已发布 Mooncakes”，直到对应操作真实成功并记录链接。
