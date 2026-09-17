# 技术设计

## 当前主线：有宿主边界的行为契约

本轮入口为 `vscode/`，不把下面的通用 DSL 模型当成 VS Code 解析器。
原生贡献文件 → 平台键位选择 → 限定布尔 when AST → 显式状态下按顺序选规则
→ 与 expected_command 对照 → 带规则标识/条件轨迹的报告。
同一纯内核编译到 wasm CLI 和 JS 导出；IO 与进程边界在调用端。
未知语法、信息不足或模型边界输出 inconclusive，不能进入 PASS。
模型的已支持范围及无法覆盖的真实宿主因素见 HOST_PROFILE.md。

## 分层

1. **文本层**：`text_utils.mbt` 和 `key_parser.mbt` 将 modifier alias、键名和连续 chord 规范化为 `KeySequence`。
2. **声明层**：`parser.mbt` 解析行式 DSL，保留行号、来源和 parser diagnostics。
3. **语义层**：`context.mbt` 计算父子 context 与平台集合；`analyzer.mbt` 运行 pairwise 冲突规则；`policy.mbt` 运行单绑定策略。
4. **工程层**：`queries.mbt`、`diff.mbt`、`graph.mbt`、`timeline.mbt` 和 `governance.mbt` 将分析结果接入迁移、审查、回归和发布门禁；`reachability.mbt` 生成 context/platform 探针矩阵。
5. **适配层**：`adapters.mbt`、`profiles.mbt`、`catalog.mbt` 和 `rules.mbt` 为不同团队接入表格、平台策略和项目约束。
6. **输出层**：`report.mbt`、`recommendations.mbt`、`schema.mbt` 提供文本、Markdown、JSON、SARIF 和机器可读 schema。

## 冲突判定

- 两个声明只有在 context 链重叠且平台集合重叠时才比较；兄弟 context 默认互斥。
- 冲突判定使用对称的 context overlap；dispatcher、selection 和可达性矩阵使用方向性的 binding-active 关系，避免子 context 泄漏到父 context。
- canonical shortcut 完全相同产生 exact conflict；较短 sequence 是较长 sequence 的前缀时产生 prefix conflict。
- priority 较高、context rank 较深的声明是 dispatcher 的候选 winner，但不会把冲突静默掉，报告仍保留两条边。
- 所有数组都按稳定声明顺序或明确的 id 排序；fingerprint 用于审计身份，不作为密码学签名。

## 数据与隐私

核心库只处理调用者传入的字符串和结构体，不扫描文件系统、不读取系统按键、不联网。
未发布的 `cli/` 包负责纯参数解析、输入校验、基线门禁和 Response(stdout, stderr, exit_code)，可不启动进程直接测试。
`cmd/main` 只读取用户显式指定的文件、严格解码 UTF-8、写入输出流并正常退出；
没有输入选项时才使用内置 demo，空 --source 不再视为未提供输入。
文件 IO/退出使用官方 x 库；分后端的极薄标准输出适配器不含分析规则。
文件先完整读入再检查大小，绑定数限制在解析后、成对分析前执行；
这些限制降低意外大配置的负担，不构成对不可信文件的安全沙箱。

## 有意不做的事情

本项目不包含操作系统 hook、GUI 编辑器、键盘记录、云端同步、自动修改用户配置和“万能快捷键推荐”。这些功能会引入平台权限、隐私和交互设计风险，超出静态分析器边界。
