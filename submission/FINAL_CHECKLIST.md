# 9 月 24 日验收前最后检查清单

## 需要申请人完成

- [ ] 在 GitHub 创建 `zhangbowen2006/MoonKeyguard` 空的公开仓库，默认分支使用 `main`。
- [ ] 确认仓库 owner、报名账户和选手信息均为张博文，不要把 MoonBVHKit 的报名资料复制到本项目。
- [ ] 提供远程仓库 URL 和默认分支确认结果。
- [ ] 在有权限的环境执行 `moon publish --frozen`；把真实 Mooncakes 页面链接发给负责人。
- [ ] 重新搜索 GitHub/Mooncakes，确认没有新的同类项目。

## 负责人完成

- [ ] `git remote show origin` 确认默认分支，检查最新提交位于默认分支。
- [ ] GitHub Actions 至少成功一次，保存真实运行链接。
- [ ] 执行 `moon check --deny-warn`、`moon build`、`moon test --deny-warn`、`moon fmt --check`、`moon info`。
- [ ] 执行 `moon package --list`，检查无 `_build`、缓存、临时文件和敏感信息。
- [ ] 发布前检查 `moon.mod` 的 name/version/license/repository/readme。
- [ ] 更新 CHANGELOG、测试记录、发布记录和申报书，不填写推测数据。
- [ ] 验收材料只提交本项目；8 月 MoonBVHKit 作为独立旧项目单独说明。
