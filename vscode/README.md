# Scoped VS Code dispatch contracts

Unreleased pure MoonBit package. No filesystem, environment lookup, editor API
or process exit is used here. This API is not present in the published 0.2.0.

`audit_sources(defaults, extension, overrides, scenarios, platform)` accepts
the source strings for a declared host snapshot and explicit expected-command
states, and returns `AuditResult { json, exit_code }`.
`audit_json` returns the same JSON directly and is exported by the JS build.
`evaluate_when` exposes the boolean subset for library consumers.

Exit 0 means supplied contracts match; 1 means a known regression; 2 means
inconclusive/invalid input. None of them certifies an actual VS Code installation.
See [host semantics and limitations](../docs/HOST_PROFILE.md) and
[the runnable fixture](../examples/vscode-review/README.md).

Build JS with `moon build --target js --release`; the example Node consumer is
`scripts/check_vscode.mjs`. Use `node scripts/test_vscode.mjs` to verify the
file CLI and direct JS consumer produce equal results for the declared examples.
