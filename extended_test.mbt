///|
test "find and select bindings" {
  let keymap = demo_keymap()
  assert_true(find_binding(keymap, "save") is Some(_))
  assert_eq(find_command(keymap, "editor.save").length(), 1)
  let selected = select_bindings(keymap, context="editor", enabled_only=true)
  assert_true(selected.bindings.length() > 0)
  assert_true(selection_to_text(selected).contains("selection"))
}

///|
test "active bindings include parent scope" {
  let active = active_bindings(demo_keymap(), "editor", "windows")
  assert_true(active.length() > 0)
  assert_true(active.filter(item => item.binding.id == "save").length() == 1)
}

///|
test "normalize and serialize keymap" {
  let keymap = normalize_keymap(demo_keymap())
  assert_eq(keymap.bindings[0].id, "quit")
  let dsl = keymap_to_dsl(keymap)
  let reparsed = parse_keymap(dsl)
  assert_true(reparsed.ok)
  assert_eq(reparsed.keymap.bindings.length(), keymap.bindings.length())
}

///|
test "merge overlay adopts higher priority" {
  let base = parse_keymap("bind save command=one keys=Ctrl+S priority=1").keymap
  let overlay = parse_keymap(
      "bind save command=two keys=Ctrl+Shift+S priority=2",
    ).keymap
  let merged = merge_keymaps(base, overlay)
  assert_eq(merged.adopted, 1)
  assert_eq(merged.keymap.bindings[0].command, "two")
  assert_eq(merged.conflicts.length(), 1)
}

///|
test "primary command picks specific binding" {
  let selected = primary_commands(demo_keymap(), "editor", "all")
  assert_true(
    selected.filter(item => item.command == "editor.palette").length() == 1,
  )
}

///|
test "graph keeps isolated nodes" {
  let keymap = demo_keymap()
  let graph = build_conflict_graph(keymap, analyze(keymap))
  assert_eq(graph.nodes.length(), keymap.bindings.length())
  assert_true(graph.edges.length() >= 2)
  assert_true(conflict_component(graph, "save").length() == 1)
  assert_true(conflict_graph_to_json(graph).contains("nodes"))
}

///|
test "graph hotspots are ranked" {
  let graph = build_conflict_graph(demo_keymap(), demo_analysis())
  let hotspots = conflict_hotspots(graph, limit=2)
  assert_eq(hotspots.length(), 2)
  assert_true(conflict_graph_to_markdown(graph).contains("Degree"))
}

///|
test "desktop profile fails reserved demo" {
  let report = audit_with_profile(demo_source(), "demo", desktop_profile())
  assert_false(report.passed)
  assert_true(report.analysis.error_count > 0)
  assert_true(profile_report_to_json(report).contains("desktop"))
}

///|
test "accessible profile rejects disabled entries" {
  let report = audit_with_named_profile(demo_source(), "demo", "accessible")
  assert_true(report.gate_messages.length() > 0)
  assert_true(profile_report_to_markdown(report).contains("Policy profile"))
}

///|
test "terminal profile has terminal reservations" {
  let rules = terminal_profile().reserved
  assert_true(rules.filter(item => item == "all:Ctrl+C").length() > 0)
}

///|
test "diff detects additions and modifications" {
  let before = parse_keymap("bind save command=one keys=Ctrl+S").keymap
  let after = parse_keymap(
      "bind save command=one keys=Ctrl+Shift+S\nbind open command=two keys=Ctrl+O",
    ).keymap
  let diff = diff_keymaps(before, after)
  assert_eq(diff.added, 1)
  assert_eq(diff.modified, 1)
  assert_eq(behavioral_changes(diff).length(), 1)
  assert_true(migration_plan(diff).contains("review"))
}

///|
test "diff apply reaches target bindings" {
  let before = parse_keymap("bind save command=one keys=Ctrl+S").keymap
  let after = parse_keymap(
      "bind save command=one keys=Ctrl+Shift+S\nbind open command=two keys=Ctrl+O",
    ).keymap
  let applied = apply_keymap_diff(before, after)
  assert_eq(applied.bindings.length(), 2)
  assert_eq(
    find_binding(applied, "save").unwrap().keys.canonical,
    "Ctrl+Shift+s",
  )
}

///|
test "csv round trip preserves declarations" {
  let csv = export_csv(demo_keymap())
  let imported = import_csv(csv)
  assert_eq(imported.rows_imported, 10)
  assert_eq(imported.diagnostics.length(), 0)
  assert_eq(
    find_binding(imported.keymap, "save").unwrap().keys.canonical,
    "Ctrl+s",
  )
}

///|
test "csv diagnostics catch missing columns" {
  let imported = import_csv("name,command\nfoo,bar")
  assert_true(imported.diagnostics.length() > 0)
  assert_true(import_report_to_text(imported).contains("missing-csv-columns"))
}

///|
test "row adapter imports and reports invalid keys" {
  let report = import_rows([
    row("save", "editor.save", "Ctrl+S"),
    row("bad", "editor.bad", "Ctrl++S"),
  ])
  assert_eq(report.rows_imported, 1)
  assert_eq(report.diagnostics.length(), 1)
}

///|
test "pipe adapter maps editor context" {
  let report = import_pipe("editor.save | Ctrl+S | editorTextFocus | mac")
  assert_eq(report.keymap.bindings[0].context, "editor")
  assert_eq(report.keymap.bindings[0].platform, "mac")
}

///|
test "runtime dispatch resolves priority" {
  let result = dispatch(
    demo_keymap(),
    "Ctrl+P",
    context="editor",
    platform="windows",
  )
  assert_eq(result.status, Matched)
  assert_eq(result.command, "editor.palette")
  assert_true(result.binding_ids.length() == 2)
}

///|
test "runtime dispatch reports prefix and miss" {
  let keymap = demo_keymap()
  let prefix_keymap = parse_keymap("bind full command=full keys=Ctrl+K,Ctrl+L").keymap
  assert_eq(dispatch(prefix_keymap, "Ctrl+K", context="global").status, Prefix)
  assert_eq(dispatch(keymap, "Ctrl+Z", context="editor").status, NoMatch)
  assert_eq(dispatch(keymap, "Ctrl++K", context="editor").status, Invalid)
}

///|
test "runtime replay counts outcomes" {
  let prefix_keymap = parse_keymap("bind full command=full keys=Ctrl+K,Ctrl+L").keymap
  let trace = replay(
    prefix_keymap,
    ["Ctrl+K", "Ctrl+K,Ctrl+L", "Ctrl+Z"],
    context="global",
  )
  assert_eq(trace.matched_count, 1)
  assert_eq(trace.prefix_count, 1)
  assert_eq(trace.no_match_count, 1)
  assert_true(dispatch_trace_to_markdown(trace).contains("Dispatch replay"))
}

///|
test "timeline records regression" {
  let clean = analyze(parse_keymap(clean_demo_source()).keymap)
  let bad = demo_analysis()
  let timeline = AuditTimeline::new("editor")
  let timeline = timeline_record_gate(timeline, "clean", "ci", clean)
  let timeline = timeline_record_gate(timeline, "bad", "ci", bad)
  assert_eq(timeline.events.length(), 2)
  assert_eq(timeline_regressions(timeline).length(), 1)
  assert_true(timeline_summary(timeline).contains("regressions=1"))
}

///|
test "timeline json is append-only" {
  let timeline = timeline_append(
    AuditTimeline::new("x"),
    "import",
    "maintainer",
    Imported,
    analyze(parse_keymap(clean_demo_source()).keymap),
    note="source",
  )
  assert_eq(timeline_latest(timeline).unwrap().sequence, 1)
  assert_true(timeline_to_json(timeline).contains("source"))
}

///|
test "catalog validates and explains" {
  let rules = default_reserved_rules()
  assert_eq(validate_catalog(rules).length(), 0)
  let binding = demo_keymap().bindings.filter(item => item.id == "quit")[0]
  assert_true(explain_reserved(binding, rules).length() > 0)
  let catalog = audit_with_catalog(demo_keymap(), rules)
  assert_true(catalog.matched.length() > 0)
  assert_true(
    catalog_report_to_markdown(catalog).contains("Reservation catalog"),
  )
}

///|
test "catalog can be applied" {
  let keymap = apply_reserved_catalog(Keymap::empty(), default_reserved_rules())
  assert_true(keymap.reserved.length() > 10)
  assert_true(catalog_to_json(default_reserved_rules()).contains("platform"))
}

///|
test "structural validator catches cycles" {
  let source =
    #|context a parent=b rank=1
    #|context b parent=a rank=1
    #|bind x command=bad keys=Ctrl+X context=a
  let report = validate_keymap(parse_keymap(source).keymap)
  assert_false(report.valid)
  assert_true(
    report.issues.filter(item => item.kind == ContextCycle).length() > 0,
  )
  assert_true(validation_to_markdown(report).contains("INVALID"))
}

///|
test "structural validator recommends descriptions" {
  let report = validate_keymap(
    parse_keymap("bind x command=good keys=Ctrl+X").keymap,
  )
  assert_true(report.warning_count > 0)
  assert_true(validation_to_json(report).contains("empty-description"))
}

///|
test "benchmark fixture is deterministic" {
  let fixture = benchmark_case(
    "dispatch",
    ["Ctrl+S", "Ctrl+K", "Ctrl+Z"],
    context="editor",
    expected_status=NoMatch,
    repetitions=2,
  )
  let result = run_benchmark(demo_keymap(), fixture)
  assert_eq(result.operations, 6)
  assert_true(result.score <= 100)
  assert_true(benchmark_result_to_json(result).contains("operations"))
}

///|
test "complexity report documents hot paths" {
  let report = complexity_report(demo_keymap(), demo_analysis())
  assert_true(report.analysis_complexity.contains("bindings"))
  assert_true(complexity_to_markdown(report).contains("Memory notes"))
}

///|
test "project rules enforce prefix and modifier" {
  let rules = {
    ..ProjectRules::default(),
    command_prefix: "app.",
    require_modifier: true,
    allowed_platforms: ["mac"],
  }
  let report = evaluate_project_rules(
    parse_keymap("bind x command=bad keys=F6 platform=linux").keymap,
    rules,
  )
  assert_false(report.passed)
  assert_eq(report.findings.length(), 3)
  assert_true(rule_report_to_markdown(report).contains("Project rule"))
}

///|
test "rules integrate into analysis" {
  let rules = { ..ProjectRules::default(), require_description: true, }
  let analysis = analyze_with_rules(
    parse_keymap("bind x command=app.x keys=Ctrl+X").keymap,
    rules,
  )
  assert_true(analysis.warning_count > 0)
  assert_true(
    rule_report_to_json(
      evaluate_project_rules(
        parse_keymap("bind x command=app.x keys=Ctrl+X").keymap,
        rules,
      ),
    ).contains("findings"),
  )
}

///|
test "recommendations are prioritized" {
  let items = health_recommendations(demo_keymap(), demo_analysis())
  assert_true(items.length() > 0)
  assert_true(items[0].priority <= items[items.length() - 1].priority)
  assert_true(
    recommendations_to_markdown(items).contains("Recommended actions"),
  )
  assert_true(recommendations_to_json(items).has_prefix("["))
}

///|
test "project capabilities stay explicit" {
  let capabilities = project_capabilities()
  assert_true(capabilities.length() >= 6)
  assert_true(
    capabilities.filter(item => item.contains("conflict")).length() == 1,
  )
}
