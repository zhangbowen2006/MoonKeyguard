///|
test "legacy pipe adapter never broadens a complex when to global" {
  let report = import_pipe(
    "save | Ctrl+S | editorTextFocus && !editorReadonly | windows",
  )
  assert_eq(report.rows_imported, 0)
  assert_eq(report.rows_seen, 1)
  assert_eq(report.diagnostics.length(), 1)
  assert_eq(report.diagnostics[0].code, "unsupported-pipe-condition")
}

///|
test "empty pipe context means global rather than editor only" {
  let report = import_pipe("save | Ctrl+S | | windows")
  assert_eq(report.rows_imported, 1)
  assert_eq(report.keymap.bindings[0].context, "global")
}

///|
test "legacy pipe does not mistake boolean OR for field separators" {
  let report = import_pipe(
    "save | Ctrl+S | editorFocus || terminalFocus | windows",
  )
  assert_eq(report.rows_imported, 0)
  assert_eq(report.diagnostics[0].code, "invalid-pipe-record")
}
