# Mooncakes 发布流程

当前仓库的 `moon.mod` 使用模块名 `zhangbowen2006/moonkeyguard`、版本 `0.3.1`、Apache-2.0、README 和 GitHub 地址。0.3.0 增加限定 VS Code 行为契约、文件 CLI 及新版 MoonBit 严格检查兼容；0.3.1 同步注册表 README 与发布元数据，不改变分析行为和公共 API。

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

2026-09-22 首次执行 0.3.0 的 `moon publish --frozen` 时，上传前的解压包检查
因 registry 依赖不能在 frozen 模式安装而失败；服务器 manifest 仍为 0.2.0。
随后发布模块移除 registry 依赖，以纯 MoonBit JSONC 预处理和有来源记录的宿主适配层替代。
`moon publish --frozen --dry-run` 已通过解压包 `moon check`，服务端返回
`202 Accepted: Dry run completed successfully`。dry-run 不等于正式发布。

修复进入公开默认分支后，[GitHub Actions 35739802114](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35739802114)
对提交 `31aeb1b` 返回 success。随后在同一提交上正式执行 `moon publish --frozen`，
解压包 `moon check` 通过，命令退出码为 0，服务端返回 `200 OK`。
公开 manifest 已核对为 `zhangbowen2006/moonkeyguard@0.3.0`、
`build_status=success`、`has_package=true`，创建时间为 2026-09-22T22:25:07+08:00。
以上记录保留首次失败和最终成功，不把 dry-run 冒充发布。

0.3.0 的注册表 README 仍是发布前快照，包含已经过时的“待发布”说明。项目没有覆盖
既有版本，而是以提交 `c3dd6f2` 同步说明和发布元数据；其
[GitHub Actions 35838483070](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35838483070)
成功后，于 2026-09-23 正式执行 `moon publish --frozen` 发布 0.3.1。
命令退出 0、服务端返回 `200 OK`；公开 manifest 已核对为 0.3.1、
`build_status=success`、`has_package=true`、`yanked=false`，注册表页面不再含旧待发布说明。
