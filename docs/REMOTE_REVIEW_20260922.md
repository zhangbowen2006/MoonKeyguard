# 2026-09-22 公开提交与远程 CI 复验

本记录对应九月黑客松初审反馈后的公开整改，不把代码规模或测试数量当作独立价值证明。

## 可核对提交

- 场景与复用整改：`8a5e4f275231b111498dd801ed3431d3e1ed3619`
- MoonBit 0.10.14 兼容修复：`46a667d1ed57c219fc876ab6a6b2599a8075add5`
- frozen 自包含发布修复：`31aeb1b668d7d05ddf4415893e9fc2cbce810254`
- 注册表说明同步：`c3dd6f2aa5ad7f5735cb800b0ad1d88c67213df5`
- 默认分支：`main`
- 最终发布提交 CI：[运行 35838483070](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35838483070)

该 CI 在 MoonBit `moon 0.1.20260920`、`moonc 0.10.14` 下完成并成功，
Check、Build、Test、Format、Public API、Package inspection、CLI 子进程、
JavaScript 测试、VS Code 双调用端、性能 smoke test 和示例步骤均为 success。

## 真实失败与修复

首次公开整改提交的 [运行 35731134763](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35731134763)
在新版编译器的严格告警检查中失败。原因是 trait 方法隐式提升已废弃，不是业务测试失败。
后续提交增加显式 `extend`、黑盒测试包限定和 test-only import；本地使用与 CI 相同的
0.10.14 工具链复验后再推送。失败记录被保留，没有改写历史或借用旧 CI。

## 本轮实际结果

- `moon check --deny-warn`：成功。
- `moon build`：成功。
- `moon test --deny-warn`：118/118。
- `moon test --target js --deny-warn`：118/118。
- `moon fmt --check`、`moon info`、`moon package --list`：成功。
- `node scripts/test_cli.mjs wasm`：26 个真实子进程用例通过。
- `node scripts/test_vscode.mjs`：6 组 fixture/声明平台、12 次消费者结果对照及 mock handler 通过。

## 仍未获得的证据

- 上述 Windows/macOS/Linux 是输入中的声明平台，不是三台操作系统实机。
- mock handler 和离线规则重放不是 VS Code GUI 或真实键盘事件验证。
- 原创故障注入样例不是客户事故，公开问题也不是外部采用证明。
- 评审是否认可收窄后的独立价值只能由组委会决定。

首次发布尝试在上传前暴露了 frozen 解压包不能安装 registry 依赖的问题；
项目没有绕过 `--frozen`，而是移除运行时 registry 依赖。后续 dry-run 已通过
干净解压包检查。最终在提交 `31aeb1b` 的 CI 成功后正式运行 `moon publish --frozen`，
命令退出 0、服务端返回 `200 OK`；[Mooncakes manifest](https://mooncakes.io/api/v0/manifest/zhangbowen2006/moonkeyguard)
先核对为 0.3.0。为修正 0.3.0 包内的发布前 README，项目随后发布 0.3.1 文档同步补丁；
其 CI 成功，正式发布命令退出 0，manifest 最终核对为 0.3.1、
`build_status=success`、`has_package=true`、`yanked=false`。
