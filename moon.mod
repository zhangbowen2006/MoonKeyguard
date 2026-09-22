// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "zhangbowen2006/moonkeyguard"

version = "0.3.0"

import {
  "moonbitlang/x@0.5.4",
}

readme = "README.md"

repository = "https://github.com/zhangbowen2006/MoonKeyguard.git"

license = "Apache-2.0"

keywords = [
  "vscode",
  "keybindings",
  "behavior-contracts",
  "regression-testing",
  "ci",
]

preferred_target = "wasm"

description = "MoonBit library for CI regression checks of scoped VS Code extension keybinding behavior contracts."
