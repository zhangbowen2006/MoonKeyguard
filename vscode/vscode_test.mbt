///|
fn probe(
  context : String,
  expected? : String = "\"save\"",
  key? : String = "ctrl+s",
) -> String {
  "[{\"name\":\"probe\",\"key\":\"" +
  key +
  "\",\"context\":" +
  context +
  ",\"expected_command\":" +
  expected +
  "}]"
}

///|
fn extension(when : String) -> String {
  "{\"contributes\":{\"keybindings\":[{\"key\":\"ctrl+s\",\"mac\":\"cmd+s\",\"command\":\"wrap\",\"when\":" +
  Json::string(when).stringify() +
  "}]}}"
}

///|
fn defaults() -> String {
  "[{\"key\":\"ctrl+s\",\"command\":\"save\",\"when\":\"editorFocus && !readonly\"}]"
}

///|
test "when logic keeps boolean precedence and parentheses" {
  let context = { "a": true, "b": false, "c": false }
  assert_eq(@vscode.evaluate_when("a || b && c", context), Ok(true))
  assert_eq(@vscode.evaluate_when("(a || b) && c", context), Ok(false))
  assert_eq(@vscode.evaluate_when("!!a && (!b || c)", context), Ok(true))
  assert_eq(@vscode.evaluate_when("", context), Ok(true))
}

///|
test "missing context does not silently mean false" {
  assert_true(@vscode.evaluate_when("missing", Map([])) is Err(_))
  assert_eq(@vscode.evaluate_when("missing && false", Map([])), Ok(false))
  assert_eq(@vscode.evaluate_when("missing || true", Map([])), Ok(true))
}

///|
test "unsupported syntax and parser limits are explicit" {
  for
    expression in [
      "editorLangId == moonbit", "resource =~ /x/", "foo in bar", "x &&", "(", "x & y",
      "x y",
    ] {
    assert_true(@vscode.evaluate_when(expression, Map([])) is Err(_))
  }
  assert_true(@vscode.evaluate_when("!".repeat(40) + "true", Map([])) is Err(_))
  assert_true(@vscode.evaluate_when(" ".repeat(1025), Map([])) is Err(_))
}

///|
test "same duplicate key set distinguishes intended mode from regression" {
  let scenario = probe(
    "{\"editorFocus\":true,\"readonly\":false,\"wrapMode\":false}",
  )
  let good = @vscode.audit_sources(
    defaults(),
    extension("editorFocus && wrapMode"),
    "[]",
    scenario,
    "windows",
  )
  let bad = @vscode.audit_sources(
    defaults(),
    extension("editorFocus"),
    "[]",
    scenario,
    "windows",
  )
  assert_eq(good.exit_code, 0)
  assert_eq(bad.exit_code, 1)
  assert_true(bad.json.contains("\"actual_command\":\"wrap\""))
  assert_true(bad.json.contains("extension[1]"))
}

///|
test "later rule wins without an invented priority value" {
  let source = "[{\"key\":\"ctrl+s\",\"command\":\"first\"},{\"key\":\"ctrl+s\",\"command\":\"last\"}]"
  assert_eq(
    @vscode.audit_sources(
      source,
      "{\"contributes\":{\"keybindings\":[]}}",
      "[]",
      probe("{}", expected="\"last\""),
      "windows",
    ).exit_code,
    0,
  )
}

///|
test "user override takes precedence over extension" {
  let result = @vscode.audit_sources(
    defaults(),
    extension("true"),
    "[{\"key\":\"ctrl+s\",\"command\":\"save\"}]",
    probe("{}"),
    "windows",
  )
  assert_eq(result.exit_code, 0)
  assert_true(result.json.contains("overrides[1]"))
}

///|
test "missing or unsupported higher-priority condition is inconclusive" {
  for condition in ["missingFlag", "language == moonbit"] {
    assert_eq(
      @vscode.audit_sources(
        defaults(),
        extension(condition),
        "[]",
        probe("{\"editorFocus\":true,\"readonly\":false}"),
        "windows",
      ).exit_code,
      2,
    )
  }
}

///|
test "unrelated unsupported condition does not change the observed key" {
  let source = "{\"contributes\":{\"keybindings\":[{\"key\":\"ctrl+w\",\"command\":\"wrap\",\"when\":\"language == moonbit\"}]}}"
  assert_eq(
    @vscode.audit_sources(
      defaults(),
      source,
      "[]",
      probe("{\"editorFocus\":true,\"readonly\":false}"),
      "windows",
    ).exit_code,
    0,
  )
}

///|
test "platform-specific extension key is honored" {
  let base = "[{\"key\":\"cmd+s\",\"command\":\"save\"}]"
  assert_eq(
    @vscode.audit_sources(
      base,
      extension("isMac"),
      "[]",
      probe("{}", expected="\"wrap\"", key="cmd+s"),
      "mac",
    ).exit_code,
    0,
  )
  assert_eq(
    @vscode.audit_sources(
      defaults(),
      extension("isMac"),
      "[]",
      probe("{\"editorFocus\":true,\"readonly\":false}"),
      "windows",
    ).exit_code,
    0,
  )
  assert_eq(
    @vscode.audit_sources(
      defaults(),
      extension("true"),
      "[]",
      probe("{\"isWindows\":false}"),
      "windows",
    ).exit_code,
    2,
  )
}

///|
test "removals args scan codes and unknown rule fields never appear safe" {
  for
    rule in [
      "{\"key\":\"ctrl+s\",\"command\":\"-save\"}", "{\"key\":\"ctrl+s\",\"command\":\"\"}",
      "{\"key\":\"ctrl+s\",\"command\":\"save\",\"args\":{}}", "{\"key\":\"ctrl+s\",\"command\":\"save\",\"systemWide\":true}",
      "{\"key\":\"ctrl+s\",\"command\":\"save\",\"priority\":3}", "{\"key\":\"ctrl+[KeyS]\",\"command\":\"save\"}",
    ] {
    assert_eq(
      @vscode.audit_sources(
        "[" + rule + "]",
        extension("false"),
        "[]",
        probe("{}"),
        "windows",
      ).exit_code,
      2,
    )
  }
}

///|
test "partial interrupted and complete chords have explicit boundaries" {
  let source = "[{\"key\":\"ctrl+k ctrl+c\",\"command\":\"comment\"}]"
  let manifest = "{\"contributes\":{\"keybindings\":[]}}"
  assert_eq(
    @vscode.audit_sources(
      source,
      manifest,
      "[]",
      probe("{}", expected="\"comment\"", key="ctrl+k ctrl+c"),
      "windows",
    ).exit_code,
    0,
  )
  assert_eq(
    @vscode.audit_sources(
      source,
      manifest,
      "[]",
      probe("{}", expected="null", key="ctrl+k"),
      "windows",
    ).exit_code,
    2,
  )
  let early = "[{\"key\":\"ctrl+k\",\"command\":\"prefix\"}]"
  assert_eq(
    @vscode.audit_sources(
      early,
      manifest,
      "[]",
      probe("{}", expected="\"comment\"", key="ctrl+k ctrl+c"),
      "windows",
    ).exit_code,
    2,
  )
}

///|
test "bad documents empty matrices and nonboolean context cannot pass" {
  let scenario = probe("{\"editorFocus\":true,\"readonly\":false}")
  assert_eq(
    @vscode.audit_sources(
      "not-json",
      extension("false"),
      "[]",
      scenario,
      "windows",
    ).exit_code,
    2,
  )
  assert_eq(
    @vscode.audit_sources(defaults(), "{}", "[]", scenario, "windows").exit_code,
    2,
  )
  assert_eq(
    @vscode.audit_sources(defaults(), extension("false"), "[]", "[]", "windows").exit_code,
    2,
  )
  assert_eq(
    @vscode.audit_sources(
      defaults(),
      extension("false"),
      "[]",
      probe("{\"readonly\":1}"),
      "windows",
    ).exit_code,
    2,
  )
}

///|
test "JSONC inputs and Unicode scenario names preserve deterministic reports" {
  let base = "[ // own fixture\n{\"key\":\"ctrl+s\",\"command\":\"save\"},]"
  let scenario = "[{\"name\":\"普通编辑\",\"key\":\"ctrl+s\",\"context\":{},\"expected_command\":\"save\"}]"
  let one = @vscode.audit_json(
    base,
    extension("false"),
    "[]",
    scenario,
    "windows",
  )
  let two = @vscode.audit_json(
    base,
    extension("false"),
    "[]",
    scenario,
    "windows",
  )
  assert_eq(one, two)
  assert_true(@json.valid(one))
  assert_true(one.contains("普通编辑"))
}

///|
test "JSONC block comments preserve string markers and reject truncation" {
  let base =
    #|[ /* fixture comment */
    #|  { "key": "ctrl+s", "command": "save//literal" },
    #|]
  let scenario =
    #|[{"name":"marker","key":"ctrl+s","context":{},"expected_command":"save//literal"}]
  assert_eq(
    @vscode.audit_sources(
      base, "{\"contributes\":{\"keybindings\":[]}}", "[]", scenario, "windows",
    ).exit_code,
    0,
  )
  let invalid = @vscode.audit_sources(
    "/* unterminated", "{\"contributes\":{\"keybindings\":[]}}", "[]", scenario,
    "windows",
  )
  assert_eq(invalid.exit_code, 2)
  assert_true(invalid.json.contains("unterminated block comment"))
}
