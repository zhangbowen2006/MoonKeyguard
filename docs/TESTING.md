# 测试记录

本页保留2026-09-14基础版记录。本轮宿主契约与文件 CLI 的实际本地记录见
[LOCAL_REVIEW_20260917.md](LOCAL_REVIEW_20260917.md)，旧结果不能替代新代码验证。

## 2026-09-14 本轮完整复验

使用隔离工具链，不替换全局安装：
- moon / moonrun 0.1.20260904（94521db）。
- moonc v0.10.12+1634b282e（2026-09-07）。
- 官方同批 core-latest 标准库，重新 bundle 后使用。
- Windows 工具链压缩包与官方 SHA256 校验一致：`3e5449e862d4979b2fc64e6a248ec5babbd110440c8f2a7bf813c6fa01d8581f`。

运行 `scripts/verify_acceptance.ps1`，逐条检查退出码：

| 命令 | 实际结果 |
| --- | --- |
| moon check --deny-warn | 0，无警告 |
| moon build | 0 |
| moon test --deny-warn | 0；89 passed，0 failed |
| moon fmt --check | 0 |
| moon info | 0 |
| git diff --exit-code -- '*.mbti' | 0，公开接口无变更 |
| moon package --list | 0，生成 0.2.0 包清单 |
| moon run cmd/main -- --format json --metrics --suggest | 0，演示 fixture 的风险报告正常输出 |
| moon run examples/basic | 0 |
| moon run examples/baseline | 0 |
| moon run cmd/main -- --source "wat value=1" --fail-on-warning | 预期 1，包含 unknown-directive 与 parser gate 失败信息 |

演示输入故意包含冲突；其报告中的错误数量不是测试失败。
当时0.2.0 CLI 的非零退出通过 abort 实现，负向测试会输出 RuntimeError。本地整改版已改为正常退出，输入错误为2、策略失败为1，详见新记录。

## 自查脚本回归验证

旧脚本仅设置 ErrorActionPreference，不能保证 native 命令非零时停止。
修复后为每一项显式检查退出码，并核验 .mbti 无差异。
在隔离的 PowerShell 函数作用域中模拟 build 退出 7，断言脚本抛错且仅调用 version/check/build，未执行后续步骤：通过。
该模拟只验证自查脚本，不增加上面的 MoonBit 测试数，也不替代真实工具运行。

## 已发现问题与纠正

0.10.10 与 0.10.12 formatter 对结构体尾逗号和长结构体换行的输出不同。
早先使用旧 formatter 的通过结果不足以证明新 CI 通过。
本轮使用官方 0.10.12 实际格式化，包含 governance.mbt 中遗漏的长结构体换行。
试验中把新编译器与旧标准库混用曾产生类型错误；已换用配套标准库并重新完整验证，未根据这些环境错误盲目修改业务类型。

## 远程状态

2026-09-22，公开整改提交 `8a5e4f2` 的
[运行 35731134763](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35731134763)
因 MoonBit 0.10.14 新增的 trait 方法提升废弃告警，在 `--deny-warn` 下失败。
项目保留该失败，并在 `46a667d` 中增加显式 extend、黑盒测试包限定和 test-only import。

[运行 35734768586](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35734768586)
对 `46a667d1ed57c219fc876ab6a6b2599a8075add5` 返回 success；Check、Build、Test、
Format、Public API snapshot、Package inspection、CLI 子进程、JavaScript 测试、
VS Code 双调用端、性能 smoke test和两个示例步骤全部 success。

[运行 35739802114](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/35739802114)
对最终发布提交 `31aeb1b668d7d05ddf4415893e9fc2cbce810254` 返回 success；同一门禁完整通过。
本地同版工具链复验为 MoonBit 118/118、JS 118/118，CLI wasm/JS/wasm-gc 各 26 个子进程用例通过。

[运行 34842814155](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/34842814155) 对 5c84363：
check/build/test 成功，Format 失败，后续检查未执行。这条失败保留为真实修复历史。

2026-09-14 推送后，[运行 34864976303](https://github.com/zhangbowen2006/MoonKeyguard/actions/runs/34864976303) 对 `fa7161ad6d1fde75d464317de14f49b1d2b831ff` 返回 success。
通过 GitHub jobs API 核验：Check、Build、Test、Format、Public API snapshot、Package inspection、CLI smoke test、Example smoke test、Baseline example smoke test 全部 success。
该结果对应上述固定提交；本记录不代替以后新提交的 CI 验证。

测试范围覆盖解析、快捷键规范化、上下文/平台冲突、适配器、图、规则、dispatcher、基线门禁和可达性矩阵。fixture 为仓库内可复现数据，不使用真实用户键盘记录。
