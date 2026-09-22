///|
test "release input builds evidence" {
  let input = @moonkeyguard.release_input(
    @moonkeyguard.parse_keymap(@moonkeyguard.clean_demo_source()).keymap,
  )
  assert_true(input.validation.valid)
  assert_true(input.analysis.ok())
  assert_true(input.profile is None)
}

///|
test "release gate reports clean baseline" {
  let keymap = @moonkeyguard.parse_keymap(@moonkeyguard.clean_demo_source()).keymap
  let gate = @moonkeyguard.release_gate(
    "clean",
    "0.1.0",
    @moonkeyguard.release_input(keymap),
  )
  assert_true(gate.passed)
  assert_eq(gate.score, 100)
  assert_true(@moonkeyguard.release_gate_to_markdown(gate).contains("PASS"))
}

///|
test "release gate blocks reserved demo" {
  let keymap = @moonkeyguard.demo_keymap()
  let input = @moonkeyguard.release_input(keymap)
  let gate = @moonkeyguard.release_gate("demo", "0.1.0", input)
  assert_false(gate.passed)
  assert_true(gate.score < 100)
  assert_true(@moonkeyguard.release_gate_to_json(gate).contains("RG002"))
}

///|
test "release gate includes profile evidence" {
  let keymap = @moonkeyguard.parse_keymap(@moonkeyguard.clean_demo_source()).keymap
  let profile = @moonkeyguard.accessible_profile()
  let input = @moonkeyguard.release_input(keymap, profile=Some(profile))
  let gate = @moonkeyguard.release_gate("clean", "0.1.0", input)
  assert_true(gate.items.filter(item => item.code == "RG003").length() == 1)
}

///|
test "release gate sees behavioral diff" {
  let before = @moonkeyguard.parse_keymap(@moonkeyguard.clean_demo_source()).keymap
  let after = @moonkeyguard.demo_keymap()
  let input = @moonkeyguard.release_input(after, baseline=Some(before))
  let gate = @moonkeyguard.release_gate("demo", "0.2.0", input)
  assert_true(gate.items.filter(item => item.code == "RG005").length() == 1)
}

///|
test "profile report metrics remain linked" {
  let report = @moonkeyguard.audit_with_named_profile(
    @moonkeyguard.clean_demo_source(),
    "clean",
    "desktop",
  )
  assert_eq(report.metrics.binding_count, report.analysis.checked_bindings)
  assert_true(report.profile.name == "desktop")
}

///|
test "graph edge weights follow severity" {
  let graph = @moonkeyguard.build_conflict_graph(
    @moonkeyguard.demo_keymap(),
    @moonkeyguard.demo_analysis(),
  )
  assert_true(graph.edges.filter(edge => edge.weight == 5).length() > 0)
}

///|
test "selection can isolate platform" {
  let selection = @moonkeyguard.select_bindings(
    @moonkeyguard.demo_keymap(),
    platform="mac",
    enabled_only=true,
  )
  assert_true(selection.bindings.length() > 0)
  for binding in selection.bindings {
    assert_true(@moonkeyguard.platforms_overlap(binding.platform, "mac"))
  }
}

///|
test "unreachable query distinguishes sibling context" {
  let values = @moonkeyguard.unreachable_bindings(
    @moonkeyguard.demo_keymap(),
    "terminal",
    "linux",
  )
  assert_true(values.filter(item => item.context == "editor").length() > 0)
}

///|
test "unreachable commands reports disabled command" {
  let values = @moonkeyguard.unreachable_commands(
    @moonkeyguard.demo_keymap(),
    "editor",
    "all",
  )
  assert_true(values.filter(item => item == "editor.legacy").length() == 1)
}

///|
test "catalog report includes unmatched rules" {
  let report = @moonkeyguard.audit_with_catalog(
    @moonkeyguard.parse_keymap("bind save command=save keys=Ctrl+S").keymap,
    @moonkeyguard.default_reserved_rules(),
  )
  assert_true(report.unmatched.length() > 0)
}

///|
test "timeline latest is optional" {
  assert_true(
    @moonkeyguard.timeline_latest(@moonkeyguard.AuditTimeline::new("empty"))
    is None,
  )
}

///|
test "timeline delta has first-event values" {
  let timeline = @moonkeyguard.timeline_append(
    @moonkeyguard.AuditTimeline::new("x"),
    "audit",
    "ci",
    Analyzed,
    @moonkeyguard.demo_analysis(),
  )
  let delta = @moonkeyguard.timeline_delta(timeline).unwrap()
  assert_eq(delta.score_delta, 0)
  assert_true(delta.errors_delta > 0)
}

///|
test "benchmark suite produces one row per fixture" {
  let fixtures = [
    @moonkeyguard.benchmark_case("a", ["Ctrl+S"], expected_status=Matched),
    @moonkeyguard.benchmark_case("b", ["Ctrl+Z"], expected_status=NoMatch),
  ]
  let results = @moonkeyguard.benchmark_suite(
    @moonkeyguard.demo_keymap(),
    fixtures,
  )
  assert_eq(results.length(), 2)
}

///|
test "structural platform validation" {
  let keymap = @moonkeyguard.parse_keymap(
      "bind x command=x keys=Ctrl+X platform=linux!",
    ).keymap
  let report = @moonkeyguard.validate_keymap(keymap)
  assert_true(
    report.issues.filter(item => item.kind == InvalidPlatform).length() == 1,
  )
}

///|
test "diff preserves unchanged rows" {
  let keymap = @moonkeyguard.parse_keymap(@moonkeyguard.clean_demo_source()).keymap
  let diff = @moonkeyguard.diff_keymaps(keymap, keymap)
  assert_eq(diff.unchanged, keymap.bindings.length())
  assert_eq(@moonkeyguard.behavioral_changes(diff).length(), 0)
}

///|
test "csv escaping handles commas" {
  let keymap = @moonkeyguard.parse_keymap(
      "bind save command=save keys=Ctrl+S description=save,buffer",
    ).keymap
  let csv = @moonkeyguard.export_csv(keymap)
  assert_true(csv.contains("\"save,buffer\""))
  assert_eq(@moonkeyguard.import_csv(csv).rows_imported, 1)
}

///|
test "runtime disabled status is observable" {
  let keymap = @moonkeyguard.parse_keymap(
      "bind old command=old keys=Alt+L enabled=false",
    ).keymap
  assert_eq(@moonkeyguard.dispatch(keymap, "Alt+L").status, Disabled)
}

///|
test "report renderers do not drop fingerprint" {
  let analysis = @moonkeyguard.demo_analysis()
  assert_true(
    @moonkeyguard.analysis_to_json(analysis).contains(analysis.fingerprint),
  )
  assert_true(
    @moonkeyguard.analysis_to_markdown(analysis).contains(analysis.fingerprint),
  )
}

///|
test "health recommendations include accessibility advice" {
  let keymap = @moonkeyguard.parse_keymap("bind f command=focus keys=F6").keymap
  let analysis = @moonkeyguard.analyze(keymap)
  let items = @moonkeyguard.health_recommendations(keymap, analysis)
  assert_true(items.filter(item => item.code == "REC-MK201").length() == 1)
}

///|
test "keymap dsl emits disabled flag" {
  let dsl = @moonkeyguard.keymap_to_dsl(
    @moonkeyguard.parse_keymap("bind old command=old keys=Alt+L enabled=false").keymap,
  )
  assert_true(dsl.contains("enabled=false"))
}

///|
test "schema describes supported boundary" {
  let schema = @moonkeyguard.keymap_schema()
  assert_eq(schema.version, "1")
  assert_true(schema.fields.length() >= 8)
  assert_true(@moonkeyguard.schema_to_json(schema).contains("directives"))
  assert_true(@moonkeyguard.schema_to_markdown(schema).contains("Required"))
  assert_true(
    @moonkeyguard.support_matrix().filter(item => item.2).length() >= 6,
  )
}
