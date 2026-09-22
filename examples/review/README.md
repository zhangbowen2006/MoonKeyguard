# 发布前发现插件快捷键回归

这是本项目编写的假想编辑器场景，不代表真实用户数据或某产品默认配置。
文件 CLI 自 0.3.0 起已发布；建议使用 Mooncakes manifest 所列的最新补丁版本。

编辑器的 Ctrl+S 用于保存；已有 Ctrl+K 与 Ctrl+K,Ctrl+C 的前缀警告被团队
暂时接受。新插件误占 Ctrl+S，新旧风险必须区分，不能为了上线把所有警告隐藏。

## 1. 复现新增错误（预期退出 1）

```sh
moon run cmd/main -- --input examples/review/regression.keymap --baseline examples/review/baseline.keymap --format json --suggest
```

顶层 exit_code=1，baseline.new_errors=1；旧前缀警告仍在 analysis 中可见。
程序不修改任一文件，建议只用于人工审查，不自动应用。

## 2. 审查修复（预期退出 0）

```sh
moon run cmd/main -- --input examples/review/fixed.keymap --baseline examples/review/baseline.keymap --format json
```

插件改用 Ctrl+Alt+E；baseline.new_errors=0、retained_count=1。
“门禁通过”只表示没有新增阻塞风险，并不表示旧警告已经解决。
增加 --fail-on-warning 会把新增警告也纳入基线门禁，不会把旧债重新当作新增。

## 3. 不使用基线的严格审查

```sh
moon run cmd/main -- --input examples/review/fixed.keymap --fail-on-warning --format markdown
```

预期退出 1：已有前缀警告仍然存在。参数/读取/编码/DSL 错误统一返回 2。
Windows 查看 $LASTEXITCODE，Bash 查看 $?。不要将返回 1 的步骤直接放进
只接受 0 的 CI，除非像本仓库的 subprocess 测试一样明确断言预期结果。

## 自动复验

```sh
node scripts/test_cli.mjs wasm
node scripts/test_cli.mjs wasm-gc
node scripts/test_cli.mjs js
```

每个后端有 26 项真实进程测试，包含完整读取 JSON、分离 stdout/stderr、
输入文件 SHA256 不变、BOM/CRLF/中文路径、非法 UTF-8、大小限制和错误退出。
