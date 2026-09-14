# 9 月 24 日验收前最后检查清单

## 申请人需要完成

- [ ] 在网络可用环境将本地 `main` 的 `371d13e` 推送到 `origin/main`（GitHub Desktop 点击 Push origin，或执行 `git push origin main`）。
- [ ] 确认 GitHub 仓库仍为 public、默认分支为 `main`，且仓库 owner、报名账户和选手信息均为张博文。
- [ ] 在报名表中提交公开申报书；手机号和邮箱只填报名平台，不上传到 GitHub。
- [ ] 重新搜索 GitHub/Mooncakes，记录查重日期和关键词；不得承诺绝对没有相似项目。

## 负责人已完成/验收前复核

- [x] 本地 `moon check --deny-warn`、`moon build`、`moon test --deny-warn`、`moon fmt --check`、`moon info` 通过。
- [x] `moon package --list` 已确认不包含 `_build`、缓存、报名版或临时文件。
- [x] `moon publish --frozen` 已实际发布 `zhangbowen2006/moonkeyguard@0.2.0`，终端返回 `Server status: 200 OK`。
- [ ] GitHub Actions 在 `371d13e` 上成功运行，并保存真实 run 链接。
- [ ] 远程默认分支最新提交与本地 `371d13e` 一致。
- [ ] 复核 README、LICENSE、CHANGELOG、第三方来源、AI 使用说明、设计/测试/发布文档渲染。
- [ ] 验收材料只提交 MoonKeyguard；8 月项目 MoonBVHKit 单独说明，不混用代码或参赛资料。