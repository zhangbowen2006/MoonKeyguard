# Mooncakes 发布流程

当前仓库的 `moon.mod` 使用模块名 `zhangbowen2006/moonkeyguard`、版本 `0.2.0`、Apache-2.0、README 和 GitHub 地址。0.2.0 包含可达性矩阵和方向性 dispatcher 修复。

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

2026-09-13 已用 `moon whoami` 确认账户为 `zhangbowen2006`，执行
`moon publish --frozen` 成功。Mooncakes manifest 返回 `200`，模块为
`zhangbowen2006/moonkeyguard@0.1.0`，`build_status=success`，`has_package=true`。
页面链接：[Mooncakes 文档](https://mooncakes.io/docs/zhangbowen2006/moonkeyguard)，
接口证据：[manifest](https://mooncakes.io/api/v0/manifest/zhangbowen2006/moonkeyguard)。
2026-09-14 已实际执行 `moon publish --frozen` 发布 0.2.0，命令退出码为 0，终端返回 `Server status: 200 OK`。对应页面仍使用稳定包文档地址：[Mooncakes 文档](https://mooncakes.io/docs/zhangbowen2006/moonkeyguard)。若后续版本发布失败，必须记录真实错误，不得用推测链接替代。
