# 测试记录

## 本地命令

以下命令在 2026-09-13 的本地 MoonBit 0.10.10 工具链上实际执行：

```text
moon fmt --check       PASS
moon check --deny-warn PASS
moon build             PASS
moon test --deny-warn  PASS (81 tests)
moon run cmd/main -- --format text --metrics --suggest PASS
moon run examples/basic PASS
```

## 覆盖范围

`moonkeyguard_test.mbt` 覆盖 parser、canonicalization、冲突、context、平台、报告和建议；`extended_test.mbt` 覆盖 graph、profile、diff、adapter、runtime、timeline、catalog、benchmark 和规则；`governance_test.mbt` 覆盖 release gate 和 schema。测试不伪造用户键盘数据，所有 fixture 都在仓库中可复现。

## 发布前追加检查

1. 在干净工作树重新运行上面的命令；
2. 运行 `moon info`，确认 `pkg.generated.mbti` 与提交一致；
3. 运行 `moon package --list`，确认包清单无 `_build`、临时文件或敏感数据；
4. 只有真实 `moon publish --frozen` 成功后才记录 Mooncakes URL。
