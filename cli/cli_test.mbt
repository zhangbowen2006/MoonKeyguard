///|
fn options(args : Array[String]) -> @cli.Options {
  @cli.parse_options(args).unwrap()
}

///|
fn field(json : Json, key : String) -> Json? {
  if json is Object(values) {
    values.get(key)
  } else {
    None
  }
}

///|
test "empty source is explicit and never means demo" {
  let settings = options(["--source", "", "--format", "json"])
  assert_eq(settings.source, Some(""))
  let response = @cli.evaluate(settings, "")
  assert_eq(response.exit_code, 0)
  let json = @json.parse(response.stdout)
  assert_eq(
    field(field(json, "analysis").unwrap(), "checked_bindings"),
    Some(Json::number(0)),
  )
}

///|
test "strict options reject ambiguous or misspelled inputs" {
  for
    args in [
      ["--input"],
      ["--input", "--format", "json"],
      ["--format", "jsoon"],
      ["--source", "x", "--input", "config.keymap"],
      ["--input", "a", "--input", "b"],
      ["--baseline", "old.keymap"],
      ["--max-bindings", "0"],
      ["--max-bindings", "10001"],
      ["--max-bindings", "many"],
      ["--name", ""],
      ["--unknown"],
      ["--format", "sarif", "--metrics"],
    ] {
    assert_true(@cli.parse_options(args) is Err(_))
  }
}

///|
test "help and format aliases are explicit" {
  assert_true(options(["-h"]).help)
  assert_eq(options(["--format", "md"]).format, "markdown")
  assert_eq(options(["--", "--max-bindings", "10"]).max_bindings, 10)
}

///|
test "parse failure is input error even without gate flag" {
  let result = @cli.evaluate(options(["--format", "json"]), "wat value=1")
  assert_eq(result.exit_code, 2)
  assert_true(result.stderr.contains("unknown-directive"))
  assert_eq(field(@json.parse(result.stdout), "ok"), Some(Json::boolean(false)))
  assert_false(result.stdout.contains("RuntimeError"))
}

///|
test "gate exit codes distinguish errors warnings and report only" {
  let conflict = "bind a command=a keys=Ctrl+A\nbind b command=b keys=Ctrl+A"
  assert_eq(@cli.evaluate(options([]), conflict).exit_code, 0)
  assert_eq(@cli.evaluate(options(["--fail-on-error"]), conflict).exit_code, 1)
  let warning = "bind a command=a keys=Ctrl+K\nbind b command=b keys=Ctrl+K,Ctrl+C"
  assert_eq(@cli.evaluate(options(["--fail-on-error"]), warning).exit_code, 0)
  assert_eq(@cli.evaluate(options(["--fail-on-warning"]), warning).exit_code, 1)
}

///|
test "json metrics suggestions and baseline stay in one object" {
  let source = "bind a command=a keys=Ctrl+A\nbind b command=b keys=Ctrl+A"
  let settings = options([
    "--input", "new.keymap", "--baseline", "old.keymap", "--format", "json", "--metrics",
    "--suggest",
  ])
  let result = @cli.evaluate(settings, source, baseline_source=source)
  let value = @json.parse(result.stdout)
  assert_eq(result.exit_code, 0)
  assert_eq(field(value, "schema_version"), Some(Json::number(1)))
  assert_eq(
    field(field(value, "metrics").unwrap(), "bindings"),
    Some(Json::number(2)),
  )
  assert_eq(
    field(field(value, "baseline").unwrap(), "new_errors"),
    Some(Json::number(0)),
  )
  assert_true(
    field(value, "suggestions") is Some(Array(items)) && items.length() > 0,
  )
  assert_eq(result.stderr, "")
}

///|
test "bad baseline cannot silently accept a regression" {
  let settings = options([
    "--input", "new", "--baseline", "old", "--format", "json",
  ])
  let result = @cli.evaluate(settings, "", baseline_source="unknown record")
  assert_eq(result.exit_code, 2)
  assert_true(result.stderr.contains("old:1:"))
  assert_eq(@cli.evaluate(settings, "").exit_code, 2)
}

///|
test "baseline gate rejects a new conflict" {
  let settings = options(["--input", "new", "--baseline", "old"])
  let before = "bind a command=a keys=Ctrl+A"
  let after = before + "\nbind b command=b keys=Ctrl+A"
  assert_eq(@cli.evaluate(settings, after, baseline_source=before).exit_code, 1)
}

///|
test "binding limits include boundary and baseline" {
  let settings = options(["--max-bindings", "1"])
  let one = "bind a command=a keys=Ctrl+A"
  assert_eq(@cli.evaluate(settings, one).exit_code, 0)
  let two = one + "\nbind b command=b keys=Ctrl+B"
  assert_eq(@cli.evaluate(settings, two).exit_code, 2)
  assert_eq(
    @cli.evaluate(
      { ..settings, baseline: Some("old"), },
      one,
      baseline_source=two,
    ).exit_code,
    2,
  )
}

///|
test "UTF BOM CRLF Unicode and escaped names remain valid JSON" {
  let settings = options([
    "--format", "json", "--name", "文档\"路径\\测试",
  ])
  let result = @cli.evaluate(
    settings, "\u{FEFF}bind 保存 command=保存 keys=Ctrl+S\r\n",
  )
  assert_eq(result.exit_code, 0)
  assert_eq(
    field(field(@json.parse(result.stdout), "analysis").unwrap(), "keymap"),
    Some(Json::string(settings.name)),
  )
}

///|
test "SARIF remains a single standard document" {
  let result = @cli.evaluate(options(["--format", "sarif"]), "")
  assert_eq(
    field(@json.parse(result.stdout), "version"),
    Some(Json::string("2.1.0")),
  )
}

///|
test "host IO errors are structured and never produce a stack trace" {
  let response = @cli.input_error(
    "cannot read \"missing.keymap\"",
    format="json",
  )
  assert_eq(response.exit_code, 2)
  assert_true(response.stderr.contains("cannot read"))
  assert_eq(
    field(@json.parse(response.stdout), "exit_code"),
    Some(Json::number(2)),
  )
}
