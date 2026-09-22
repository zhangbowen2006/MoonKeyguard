# VS Code 宿主配置边界

Profile ID：vscode-ordered-boolean-v1。2026-09-22 已进入公开 `main` 并通过对应远程 CI；
Mooncakes 0.3.0 已发布，公开 manifest 显示构建成功且包可用。
工程测试证明声明模型按以下范围工作，不代表与完整 VS Code resolver 等价。

## 输入与判定

- defaults：调用者提供的相关默认规则数组；不得含待测扩展的重复条目。
- extension：实际 package.json 中的 contributes.keybindings；支持对象或数组。
- overrides：目标用户配置中的规则数组。不会读取操作系统用户目录。
- scenarios：1..128 个有名称的键位、布尔 context、expected_command 契约；
  expected_command=null 表示该探针应没有命令，不能用空字符串代替。
- platform：显式 windows、mac、linux；不从运行测试的机器推断。

默认快照 → 待测扩展 → 用户覆盖按此顺序组成列表。调用者负责提供和目标安装一致的有关规则及其顺序，
本工具不会重建多扩展安装的注册权重，也不会发现缺失的扩展。因此只有相关规则齐全时，
结果才可作为该配置的离线检查，不能解释为“所有已安装扩展已检查”。

按照官方键盘规则文档，模型从后往前选择满足按键和 when 的条目；不使用旧 DSL 的自定义 priority。
扩展的 key 可由 win/mac/linux 覆盖；默认及用户数组必须已经是所选平台的键位快照。
返回 trace 中 defaults[1]/extension[1]/overrides[1] 是一开始的数组序号，不冒充源码行号。
该模型判断分派到哪个命令，不执行命令，也不证明命令注册、enablement、文件权限或处理器行为。

参考：[键盘规则](https://code.visualstudio.com/docs/configure/keybindings#keyboard-rules)、
[扩展贡献格式](https://code.visualstudio.com/api/references/contribution-points#contributes.keybindings)。

## 支持的 when 与按键

when 支持布尔键、true/false、!、&&、||、括号，优先级为 ! > && > ||。
必要状态缺失时返回未知；不把未提供的值自动当成 false。逻辑确定结果可短路确定：
例如 missing && false 为 false，missing || true 为 true。
isWindows/isMac/isLinux 由 platform 注入，与输入冲突时拒绝。
条件长度上限1024码元、128个token、括号/否定嵌套32层。

键名范围为字母、数字、F1..F24 和文档列明的常见导航键，最多四段空格分隔 chord。
不解析 OEM 键、扫描码、标点布局；输入会因无法可靠建模而拒绝。
完整 chord 的中间步骤若已被短绑定消费或中断，或者只提供了半段 chord，返回不确定，
不假装实现宿主超时、重新分派与焦点变化。
具体布尔语法依据：[when 条件说明](https://code.visualstudio.com/api/references/when-clause-contexts)。

## 不能声称支持的范围

等号/数值比较、正则、in/not in、非布尔 context、移除规则、空命令禁用、
args、systemWide、未知规则字段、真实键盘布局/AltGr/IME、OS 截获、
chord 超时、运行过程中 context 更新、命令执行及实际的第三方扩展注册顺序。
命中探针的未覆盖规则不会被悄悄丢弃为“无冲突”。不相关键位上的未知 when 不影响该探针，
但不因此宣称那条规则本身已经验证。文件先由纯 MoonBit 处理 JSONC 注释和尾逗号，
再用 core JSON 解析；解析成功不替代 VS Code schema 校验。
每份源文档最多1 Mi码元，规则层各最多2000条；这是资源限制而非恶意输入沙箱。

## 输出语义

- pass / 0：列出的契约在给定快照及已支持语义下符合。
- regression / 1：至少一个已知分派结果不符合 expected_command。
- inconclusive / 2：输入不合法、状态不足或触及模型边界；不能作为成功放行。

不在报告里的状态没有被验证。实际键盘问题仍需 VS Code 排障日志和目标机器复核。
