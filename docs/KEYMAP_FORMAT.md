# Keymap DSL

每行一个 directive，`#` 后面的内容是注释。字段使用 `key=value`，值不包含空格；连续 chord 使用逗号。

```text
keymap name=editor version=1
context global parent= rank=0 description=all-windows
context editor parent=global rank=10 description=text-editor
reserve Cmd+Q platform=mac
bind save command=editor.save keys=Ctrl+S context=editor platform=all priority=10 enabled=true description=save-buffer
```

## 规范化

- `ctrl`、`control` → `Ctrl`；`cmd`、`command`、`meta` → `Cmd`；`option` → `Alt`。
- 单字母键 canonical 为小写字母，因此 `Ctrl+S` 的报告形式为 `Ctrl+s`。
- `Esc`、`Return`、`Del`、方向键等常见别名会转换为完整名称。
- 重复 modifier 或一个 chord 中出现两个普通键会产生 parser error。

## 语义

`global` 是内置根 context。父 context 与子 context 会重叠；兄弟 context 只有在显式建立相同链关系时才会重叠。`all` 与任意平台重叠，逗号或 `|` 分隔的平台集合按集合交集判定。

## CSV

`export_csv` 产生固定列：`id,command,keys,context,platform,priority,enabled,description`。`import_csv` 会报告缺列、缺值和非法键，不会静默丢弃失败行。
