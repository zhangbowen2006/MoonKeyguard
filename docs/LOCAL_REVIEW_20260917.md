# 2026-09-17 本地整改复验

后续公开提交和新 CI 结果见 [REMOTE_REVIEW_20260922.md](REMOTE_REVIEW_20260922.md)。
本页保留当日尚未推送时的历史状态，不回写成事后结果。

本轮新增内容未推送、未发布。基准 Git HEAD 为597e9a8，以下命令针对本轮修改后的工作树实际执行，
不能引用旧CI为新代码背书。测试证据与需求/独立价值是否获评委认可分开判断。

## 工具链

MoonBit moon/moonrun 0.1.20260904，moonc v0.10.12+1634b282e，使用配套core；
模块依赖官方moonbitlang/x@0.5.4。工具链在忽略的_build/toolchain内，不替换全局安装。

## 实际结果

| 命令 | 结果 |
| --- | --- |
| moon info | 成功；审阅新增cli/vscode接口，旧根包公共接口未改变 |
| moon fmt / moon fmt --check | 成功 |
| moon check --deny-warn | 成功 |
| moon build | 成功 |
| moon test --deny-warn | 117通过，0失败 |
| moon test --target js --deny-warn | 同一套117测试通过 |
| node scripts/test_cli.mjs wasm | 26次真实CLI进程用例通过 |
| node scripts/test_cli.mjs js | 26次真实CLI进程用例通过 |
| node scripts/test_cli.mjs wasm-gc | 26次真实CLI进程用例通过 |
| node scripts/test_vscode.mjs | 六组fixture/声明平台、12次消费者结果对照通过；mock扩展处理器通过 |
| moon check --target native --deny-warn | 类型检查成功，不代表native可执行程序运行成功 |
| moon package --list | 成功，清单不含_build、依赖缓存、报名联系方式和临时开发宿主profile |
| git diff --check | 成功 |

CLI负向用例包括缺少/重复/错误参数、未知格式、缺失或目录路径、非法UTF-8、
空source、输入大小/绑定上限、解析错误、错误基线、门禁失败及大JSON管道完整性。
失败码1/2是断言预期结果，不伪造为所有命令都退出0。

## 本次驳回理由的具体复现

反例与修复的Ctrl+S/Cmd+S声明不变，只改变when。
反例在普通编辑、选区但模式关闭、只读三种契约中选择了错误命令，返回1；
修复文件的五种显式状态返回0。CLI及编译后JS API结果一致。
条件缺失或语法超出profile返回2；旧pipe适配器的未知when不再被改成global。

## 明确没有完成的验证

- Windows机器上输入windows/mac/linux标签是声明平台模拟，不是三台操作系统实机运行。
- mock VS Code对象、CLI/JS结果对照都不是VS Code GUI或真实键盘事件验证。
- 原创开发扩展不代表外部使用者、线上案例或Marketplace发布；手工核对步骤尚待执行。
- native可执行程序上轮构建因缺少系统C编译器失败，本轮仅声明类型检查通过。
- 性能基准为合成输入；旧run_benchmark匹配率不是计时结果。本轮不宣称完成新的性能优化。
- 尚无本轮远程CI、新版Mooncakes发布或组委会批准记录。

## 下一步发布前动作

保存真实本地提交 → 推送默认分支 → 取得该提交CI → 检查新版本及包内容 → 实际发布并核验页面。
在此之前，本轮申报书必须标为本地整改版。另需目标宿主日志及维护者反馈支持实际复用价值。
