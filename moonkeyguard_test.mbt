///|
test "canonicalizes modifier aliases" {
  assert_eq(canonical_keys("ctrl+shift+s"), "Ctrl+Shift+s")
  assert_eq(canonical_keys("cmd+q"), "Cmd+q")
  assert_eq(canonical_keys("Control+Option+P"), "Ctrl+Alt+p")
}

///|
test "parses comma separated chords" {
  let parsed = parse_keys("Ctrl+K,Ctrl+L")
  match parsed {
    Ok(sequence) => {
      assert_eq(sequence.steps, ["Ctrl+k", "Ctrl+l"])
      assert_eq(sequence.key_count, 2)
      assert_true(sequence.has_modifier)
    }
    Err(message) => fail("expected sequence: " + message)
  }
}

///|
test "rejects empty and malformed chords" {
  match parse_keys("") {
    Ok(_) => fail("empty sequence accepted")
    Err(_) => ()
  }
  match parse_keys("Ctrl++S") {
    Ok(_) => fail("empty chord component accepted")
    Err(_) => ()
  }
  match parse_keys("Ctrl+S+L") {
    Ok(_) => fail("two non-modifier keys accepted")
    Err(_) => ()
  }
}

///|
test "prefix relation is directional" {
  let first = parse_keys("Ctrl+K").unwrap()
  let second = parse_keys("Ctrl+K,Ctrl+L").unwrap()
  assert_true(key_prefix(first, second))
  assert_false(key_prefix(second, first))
  assert_false(key_prefix(first, first))
}

///|
test "parses context and binding records" {
  let source =
    #|keymap name=test version=3
    #|context editor parent=global rank=5 description=editor
    #|bind save command=editor.save keys=Ctrl+S context=editor platform=all priority=2 description=save
  let parsed = parse_keymap(source)
  assert_true(parsed.ok)
  assert_eq(parsed.keymap.name, "test")
  assert_eq(parsed.keymap.version, "3")
  assert_eq(parsed.keymap.contexts.length(), 2)
  assert_eq(parsed.keymap.bindings.length(), 1)
  assert_eq(parsed.keymap.bindings[0].command, "editor.save")
  assert_eq(parsed.keymap.bindings[0].priority, 2)
}

///|
test "unknown directive is a parser diagnostic" {
  let parsed = parse_keymap("wat value=1")
  assert_false(parsed.ok)
  assert_eq(parsed.diagnostics[0].code, "unknown-directive")
}

///|
test "reserved records retain platform" {
  let parsed = parse_keymap("reserve Ctrl+Alt+Delete platform=windows")
  assert_true(parsed.ok)
  assert_eq(parsed.keymap.reserved, ["windows:Ctrl+Alt+Delete"])
}

///|
test "disabled records remain available for migration" {
  let parsed = parse_keymap("bind old command=legacy keys=Alt+L enabled=false")
  assert_true(parsed.ok)
  assert_false(parsed.keymap.bindings[0].enabled)
  let analysis = analyze(parsed.keymap)
  assert_eq(analysis.info_count, 1)
  assert_eq(analysis.count_kind(DisabledBinding), 1)
}

///|
test "exact conflict is an error" {
  let source =
    #|bind first command=one keys=Ctrl+P
    #|bind second command=two keys=Ctrl+P
  let analysis = analyze(parse_keymap(source).keymap)
  assert_eq(analysis.count_kind(ExactConflict), 1)
  assert_true(analysis.error_count >= 1)
  assert_false(analysis.ok())
}

///|
test "same command is informational" {
  let source =
    #|bind first command=one keys=Ctrl+P
    #|bind second command=one keys=Ctrl+P
  let analysis = analyze(parse_keymap(source).keymap)
  assert_eq(analysis.count_kind(DuplicateCommand), 1)
  assert_eq(analysis.count_kind(ExactConflict), 0)
}

///|
test "prefix conflict is a warning" {
  let source =
    #|bind first command=one keys=Ctrl+K
    #|bind second command=two keys=Ctrl+K,Ctrl+L
  let analysis = analyze(parse_keymap(source).keymap)
  assert_eq(analysis.count_kind(PrefixConflict), 1)
  assert_eq(analysis.warning_count, 1)
}

///|
test "sibling contexts do not conflict" {
  let source =
    #|context editor parent=global rank=1
    #|context terminal parent=global rank=1
    #|bind first command=one keys=Ctrl+P context=editor
    #|bind second command=two keys=Ctrl+P context=terminal
  let analysis = analyze(parse_keymap(source).keymap)
  assert_eq(analysis.count_kind(ExactConflict), 0)
}

///|
test "child and parent contexts conflict" {
  let source =
    #|context editor parent=global rank=1
    #|bind first command=one keys=Ctrl+P context=global
    #|bind second command=two keys=Ctrl+P context=editor
  let analysis = analyze(parse_keymap(source).keymap)
  assert_eq(analysis.count_kind(ExactConflict), 1)
}

///|
test "platform overlap understands all" {
  assert_true(platforms_overlap("all", "mac"))
  assert_true(platforms_overlap("windows|linux", "linux"))
  assert_false(platforms_overlap("mac", "windows"))
}

///|
test "reserved policy is enforced" {
  let source =
    #|reserve Ctrl+C platform=all
    #|bind interrupt command=terminal.interrupt keys=Ctrl+C platform=linux
  let analysis = analyze(parse_keymap(source).keymap)
  assert_eq(analysis.count_kind(ReservedShortcut), 1)
  assert_true(analysis.error_count >= 1)
}

///|
test "modifierless shortcut has accessibility finding" {
  let analysis = analyze(
    parse_keymap("bind focus command=focus keys=F6").keymap,
  )
  assert_eq(analysis.count_kind(AccessibilityRisk), 1)
}

///|
test "unknown context is an error" {
  let analysis = analyze(
    parse_keymap("bind focus command=focus keys=F6 context=missing").keymap,
  )
  assert_eq(analysis.count_kind(InvalidContext), 1)
}

///|
test "duplicate ids are detected" {
  let source =
    #|bind same command=one keys=Ctrl+A
    #|bind same command=two keys=Ctrl+B
  let analysis = analyze(parse_keymap(source).keymap)
  assert_eq(analysis.count_kind(InvalidRecord), 1)
}

///|
test "fingerprint is deterministic" {
  let source = clean_demo_source()
  let one = analyze(parse_keymap(source).keymap)
  let two = analyze(parse_keymap(source).keymap)
  assert_eq(one.fingerprint, two.fingerprint)
  assert_eq(one.fingerprint.length(), 16)
}

///|
test "clean demo passes" {
  let analysis = analyze(parse_keymap(clean_demo_source()).keymap)
  assert_true(analysis.ok())
  assert_eq(analysis.error_count, 0)
}

///|
test "demo has expected findings" {
  let analysis = demo_analysis()
  assert_eq(analysis.count_kind(ExactConflict), 1)
  assert_eq(analysis.count_kind(PrefixConflict), 1)
  assert_eq(analysis.count_kind(ReservedShortcut), 2)
  assert_eq(analysis.count_kind(DisabledBinding), 1)
}

///|
test "text report contains summary" {
  let report = analysis_to_text(demo_analysis())
  assert_true(report.contains("MoonKeyguard analysis"))
  assert_true(report.contains("fingerprint"))
  assert_true(report.contains("MK001"))
}

///|
test "json report has stable fields" {
  let json = analysis_to_json(demo_analysis())
  assert_true(json.contains("\"findings\""))
  assert_true(json.contains("\"fingerprint\""))
  assert_true(json.contains("\"severity\":\"error\""))
}

///|
test "markdown report has tables" {
  let markdown = analysis_to_markdown(demo_analysis())
  assert_true(markdown.contains("| Severity | Code |"))
  assert_true(markdown.contains("editor-demo"))
}

///|
test "sarif report has version" {
  let sarif = analysis_to_sarif(demo_analysis())
  assert_true(sarif.contains("2.1.0"))
  assert_true(sarif.contains("MoonKeyguard"))
}

///|
test "metrics describe keymap" {
  let metrics = keymap_metrics(demo_keymap())
  assert_eq(metrics.binding_count, 10)
  assert_eq(metrics.context_count, 3)
  assert_true(metrics.documented_count >= 10)
  assert_true(metrics_to_json(metrics).contains("density_score"))
}

///|
test "suggestions are free and deterministic" {
  let keymap = demo_keymap()
  let analysis = analyze(keymap)
  let first = suggest_all(keymap, analysis)
  let second = suggest_all(keymap, analysis)
  assert_eq(first, second)
  assert_true(first.length() > 0)
  for item in first {
    assert_true(item.replacement != item.current)
  }
}

///|
test "exit code follows policy" {
  let clean = analyze(parse_keymap(clean_demo_source()).keymap)
  let demo = demo_analysis()
  assert_eq(analysis_exit_code(clean), 0)
  assert_eq(analysis_exit_code(demo), 1)
  assert_eq(analysis_exit_code(clean, fail_on_warning=true), 0)
}
