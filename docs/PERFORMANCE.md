# 实际性能测量

0.3.x 功能已推送、通过远程 CI 并发布至 Mooncakes。这里测的是时间，不是旧
run_benchmark 的匹配率分数；旧 API 是确定性的 dispatcher 回归 fixture。

## 复现

```sh
node scripts/benchmark.mjs --quick
node scripts/benchmark.mjs --label before
```

脚本构建 release/wasm，在 MoonBit 内用 core/bench 单调时钟测量解析和分析。
每种配置先预热一次，再测五次，原始样本和 min/mean/max 都保留。
快速模式每项测两次，仅做功能烟测，不设置容易受机器噪声影响的时间阈值。
启动、编译、文件 IO、报告渲染不计入这里的耗时，不能当作端到端 CLI 延迟。

输出在被忽略的 _build/benchmarks 中，记录时间、平台、CPU、工具链、
Git HEAD、工作树是否有未提交内容和实际测量源码 SHA256，不记录主机名或联系方式。
若 worktree_dirty=true，不能把样本声称为纯净 HEAD 的结果。

## 样本范围与限制

- sparse：100、500、1000 条不同的符号键名，预期零冲突。
- dense：100 条同键绑定，预期 4950 条成对冲突，测试高输出密度。
- prefix：300 条共享前缀序列，预期 299 个前缀警告。
- 每个样本验证解析成功、绑定数和发现数，防止把“未执行完整工作”当作加速。
- Key1 等键名仅用于规模测试，不是物理键盘布局，也不是客户配置数据。
- 当前仍有成对枚举，最坏情况具有平方级成本；长上下文链、别名平台
  和冲突密集配置可能更慢，增加 --max-bindings 前应针对自己的数据测量。
- 单机五次样本不代表所有设备或所有真实应用的表现，不承诺实时或固定吞吐量。
