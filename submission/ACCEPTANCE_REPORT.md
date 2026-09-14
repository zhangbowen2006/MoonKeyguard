# 验收证据报告（持续更新）

项目：MoonKeyguard  
申请人：张博文  
模块：`zhangbowen2006/moonkeyguard`  
状态：已完成本地自审和 0.2.0 Mooncakes 发布；本轮 GitHub 提交待网络恢复后推送。

| 要求 | 当前证据 | 风险/下一步 |
| --- | --- | --- |
| MoonBit 为主要语言 | 根目录 生产 `.mbt` 约 5.3k 行；89 个测试；`moon.mod` | 远程 CI 需再次验证 |
| 公开可访问仓库 | [GitHub](https://github.com/zhangbowen2006/MoonKeyguard) 为 public，默认分支 `main`；最新本地提交 `352a238`（尚待推送；功能提交为 `371d13e`） | 持续维护 |
| README 完整 | `README.md` 覆盖用途、API、边界、示例、测试和发布 | 推送后复核远程页面渲染 |
| 可运行示例 | `examples/basic`，`moon run examples/basic` 已验证 | CI 保持示例步骤 |
| CI | [历史 Actions run 34755575667；本轮提交待新 run](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/34755575667) success | 推送后等待本轮 CI 绿色记录 |
| 可运行测试 | 89 tests，`moon test --deny-warn` PASS | 不伪造远程徽章 |
| 正常构建 | `moon build` PASS | 发布前再次在干净树执行 |
| Mooncakes | [manifest](https://mooncakes.io/api/v0/manifest/zhangbowen2006/moonkeyguard) 返回 200，`0.2.0`、构建成功、包存在 | 已完成 0.2.0 发布；推送后复核远程 CI |
| 可追踪开发过程 | 本地 `main` 已包含 12 个有意义提交；远程 `origin/main` 仍为 7 个提交 | 继续保留真实提交 |
| 功能边界/维护价值 | `docs/ARCHITECTURE.md`、`PROJECT_PROPOSAL.md`、schema API | 持续维护 Issue/CHANGELOG |
| 开源许可证 | 根目录 Apache-2.0 `LICENSE` | 检查远程包清单 |
| 查重独立性 | `docs/DEDUPLICATION.md` | 报名前重跑搜索 |

## 已实际运行命令

```text
moon fmt --check                 PASS
moon check --deny-warn           PASS
moon build                       PASS
moon test --deny-warn            PASS (89 tests)
moon run cmd/main -- --format text --metrics --suggest  PASS
moon run examples/basic          PASS
```

发布后复核命令：

```text
moon info
moon package --list
moon publish --frozen  # 重复发布同版本应返回真实 409，不重复伪造发布
```
