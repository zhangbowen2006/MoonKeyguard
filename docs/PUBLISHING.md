# Mooncakes 发布流程

当前仓库的 `moon.mod` 已使用模块名 `zhangbowen2006/moonkeyguard`、版本 `0.1.0`、Apache-2.0、README 和预期 GitHub 地址。尚未在本地声称已发布到 Mooncakes。

发布前：

```bash
moon check --deny-warn
moon build
moon test --deny-warn
moon fmt --check
moon info
moon package --list
```

确认登录凭据和版本号后执行：

```bash
moon publish --frozen
```

把命令的真实输出、版本、日期和 Mooncakes 页面链接写入 `submission/ACCEPTANCE_REPORT.md` 与 CHANGELOG。若登录失败、网络失败或包名已占用，记录真实错误并暂停，不得用推测链接替代。
