# 验收证据报告（持续更新）

项目：MoonKeyguard  
申请人：张博文  
模块：`zhangbowen2006/moonkeyguard`  
状态：本地工程已完成首轮自审；公开 GitHub 仓库、Mooncakes 发布链接和默认分支需在远程操作完成后补录。

| 要求 | 当前证据 | 风险/下一步 |
| --- | --- | --- |
| MoonBit 为主要语言 | 根目录 生产 `.mbt` 约 5.3k 行；`moon.mod` | 远程 CI 需再次验证 |
| 公开可访问仓库 | 预期 URL 已写入 `moon.mod` | 尚未创建远程仓库，不能声称公开 |
| README 完整 | `README.md` 覆盖用途、API、边界、示例、测试和发布 | 远程页面创建后复核渲染 |
| 可运行示例 | `examples/basic`，`moon run examples/basic` 已验证 | CI 保持示例步骤 |
| CI | `.github/workflows/ci.yml` | 推送后查看真实 Actions 结果 |
| 可运行测试 | 81 tests，`moon test --deny-warn` PASS | 不伪造远程徽章 |
| 正常构建 | `moon build` PASS | 发布前再次在干净树执行 |
| Mooncakes | `moon.mod` 已准备，未声称发布 | 需登录后执行 `moon publish --frozen` |
| 可追踪开发过程 | 本地 Git 提交逐步记录 | 需创建远程并推送真实历史 |
| 功能边界/维护价值 | `docs/ARCHITECTURE.md`、`PROJECT_PROPOSAL.md`、schema API | 持续维护 Issue/CHANGELOG |
| 开源许可证 | 根目录 Apache-2.0 `LICENSE` | 检查远程包清单 |
| 查重独立性 | `docs/DEDUPLICATION.md` | 报名前重跑搜索 |

## 已实际运行命令

```text
moon fmt --check                 PASS
moon check --deny-warn           PASS
moon build                       PASS
moon test --deny-warn            PASS (81 tests)
moon run cmd/main -- --format text --metrics --suggest  PASS
moon run examples/basic          PASS
```

下列命令必须在发布前真实执行并把输出补到本文件：

```text
moon info
moon package --list
moon publish --frozen
```
