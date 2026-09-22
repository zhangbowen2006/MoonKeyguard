///|
test "find and select bindings" {
  let keymap = @moonkeyguard.demo_keymap()
  assert_true(@moonkeyguard.find_binding(keymap, "save") is Some(_))
  assert_eq(@moonkeyguard.find_command(keymap, "editor.save").length(), 1)
  let selected = @moonkeyguard.select_bindings(
    keymap,
    context="editor",
    enabled_only=true,
  )
  assert_true(selected.bindings.length() > 0)
  assert_true(@moonkeyguard.selection_to_text(selected).contains("selection"))
}

///|
test "active bindings include parent scope" {
  let active = @moonkeyguard.active_bindings(
    @moonkeyguard.demo_keymap(),
    "editor",
    "windows",
  )
  assert_true(active.length() > 0)
  assert_true(active.filter(item => item.binding.id == "save").length() == 1)
}

///|
test "normalize and serialize keymap" {
  let keymap = @moonkeyguard.normalize_keymap(@moonkeyguard.demo_keymap())
  assert_eq(keymap.bindings[0].id, "quit")
  let dsl = @moonkeyguard.keymap_to_dsl(keymap)
  let reparsed = @moonkeyguard.parse_keymap(dsl)
  assert_true(reparsed.ok)
  assert_eq(reparsed.keymap.bindings.length(), keymap.bindings.length())
}

///|
test "merge overlay adopts higher priority" {
  let base = @moonkeyguard.parse_keymap(
      "bind save command=one keys=Ctrl+S priority=1",
    ).keymap
  let overlay = @moonkeyguard.parse_keymap(
      "bind save command=two keys=Ctrl+Shift+S priority=2",
    ).keymap
  let merged = @moonkeyguard.merge_keymaps(base, overlay)
  assert_eq(merged.adopted, 1)
  assert_eq(merged.keymap.bindings[0].command, "two")
  assert_eq(merged.conflicts.length(), 1)
}

///|
test "primary command picks specific binding" {
  let selected = @moonkeyguard.primary_commands(
    @moonkeyguard.demo_keymap(),
    "editor",
    "all",
  )
  assert_true(
    selected.filter(item => item.command == "editor.palette").length() == 1,
  )
}

///|
test "graph keeps isolated nodes" {
  let keymap = @moonkeyguard.demo_keymap()
  let graph = @moonkeyguard.build_conflict_graph(
    keymap,
    @moonkeyguard.analyze(keymap),
  )
  assert_eq(graph.nodes.length(), keymap.bindings.length())
  assert_true(graph.edges.length() >= 2)
  assert_true(@moonkeyguard.conflict_component(graph, "save").length() == 1)
  assert_true(@moonkeyguard.conflict_graph_to_json(graph).contains("nodes"))
}

///|
test "graph hotspots are ranked" {
  let graph = @moonkeyguard.build_conflict_graph(
    @moonkeyguard.demo_keymap(),
    @moonkeyguard.demo_analysis(),
  )
  let hotspots = @moonkeyguard.conflict_hotspots(graph, limit=2)
  assert_eq(hotspots.length(), 2)
  assert_true(
    @moonkeyguard.conflict_graph_to_markdown(graph).contains("Degree"),
  )
}

///|
test "desktop profile fails reserved demo" {
  let report = @moonkeyguard.audit_with_profile(
    @moonkeyguard.demo_source(),
    "demo",
    @moonkeyguard.desktop_profile(),
  )
  assert_false(report.passed)
  assert_true(report.analysis.error_count > 0)
  assert_true(@moonkeyguard.profile_report_to_json(report).contains("desktop"))
}

///|
test "accessible profile rejects disabled entries" {
  let report = @moonkeyguard.audit_with_named_profile(
    @moonkeyguard.demo_source(),
    "demo",
    "accessible",
  )
  assert_true(report.gate_messages.length() > 0)
  assert_true(
    @moonkeyguard.profile_report_to_markdown(report).contains("Policy profile"),
  )
}

///|
test "terminal profile has terminal reservations" {
  let rules = @moonkeyguard.terminal_profile().reserved
  assert_true(rules.filter(item => item == "all:Ctrl+C").length() > 0)
}

///|
test "diff detects additions and modifications" {
  let before = @moonkeyguard.parse_keymap("bind save command=one keys=Ctrl+S").keymap
  let after = @moonkeyguard.parse_keymap(
      "bind save command=one keys=Ctrl+Shift+S\nbind open command=two keys=Ctrl+O",
    ).keymap
  let diff = @moonkeyguard.diff_keymaps(before, after)
  assert_eq(diff.added, 1)
  assert_eq(diff.modified, 1)
  assert_eq(@moonkeyguard.behavioral_changes(diff).length(), 1)
  assert_true(@moonkeyguard.migration_plan(diff).contains("review"))
}

///|
test "diff apply reaches target bindings" {
  let before = @moonkeyguard.parse_keymap("bind save command=one keys=Ctrl+S").keymap
  let after = @moonkeyguard.parse_keymap(
      "bind save command=one keys=Ctrl+Shift+S\nbind open command=two keys=Ctrl+O",
    ).keymap
  let applied = @moonkeyguard.apply_keymap_diff(before, after)
  assert_eq(applied.bindings.length(), 2)
  assert_eq(
    @moonkeyguard.find_binding(applied, "save").unwrap().keys.canonical,
    "Ctrl+Shift+s",
  )
}

///|
test "csv round trip preserves declarations" {
  let csv = @moonkeyguard.export_csv(@moonkeyguard.demo_keymap())
  let imported = @moonkeyguard.import_csv(csv)
  assert_eq(imported.rows_imported, 10)
  assert_eq(imported.diagnostics.length(), 0)
  assert_eq(
    @moonkeyguard.find_binding(imported.keymap, "save").unwrap().keys.canonical,
    "Ctrl+s",
  )
}

///|
test "csv diagnostics catch missing columns" {
  let imported = @moonkeyguard.import_csv("name,command\nfoo,bar")
  assert_true(imported.diagnostics.length() > 0)
  assert_true(
    @moonkeyguard.import_report_to_text(imported).contains(
      "missing-csv-columns",
    ),
  )
}

///|
test "row adapter imports and reports invalid keys" {
  let report = @moonkeyguard.import_rows([
    @moonkeyguard.row("save", "editor.save", "Ctrl+S"),
    @moonkeyguard.row("bad", "editor.bad", "Ctrl++S"),
  ])
  assert_eq(report.rows_imported, 1)
  assert_eq(report.diagnostics.length(), 1)
}

///|
test "pipe adapter maps editor context" {
  let report = @moonkeyguard.import_pipe(
    "editor.save | Ctrl+S | editorTextFocus | mac",
  )
  assert_eq(report.keymap.bindings[0].context, "editor")
  assert_eq(report.keymap.bindings[0].platform, "mac")
}

///|
test "runtime dispatch resolves priority" {
  let result = @moonkeyguard.dispatch(
    @moonkeyguard.demo_keymap(),
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
  let keymap = @moonkeyguard.demo_keymap()
  let prefix_keymap = @moonkeyguard.parse_keymap(
      "bind full command=full keys=Ctrl+K,Ctrl+L",
    ).keymap
  assert_eq(
    @moonkeyguard.dispatch(prefix_keymap, "Ctrl+K", context="global").status,
    Prefix,
  )
  assert_eq(
    @moonkeyguard.dispatch(keymap, "Ctrl+Z", context="editor").status,
    NoMatch,
  )
  assert_eq(
    @moonkeyguard.dispatch(keymap, "Ctrl++K", context="editor").status,
    Invalid,
  )
}

///|
test "runtime replay counts outcomes" {
  let prefix_keymap = @moonkeyguard.parse_keymap(
      "bind full command=full keys=Ctrl+K,Ctrl+L",
    ).keymap
  let trace = @moonkeyguard.replay(
    prefix_keymap,
    ["Ctrl+K", "Ctrl+K,Ctrl+L", "Ctrl+Z"],
    context="global",
  )
  assert_eq(trace.matched_count, 1)
  assert_eq(trace.prefix_count, 1)
  assert_eq(trace.no_match_count, 1)
  assert_true(
    @moonkeyguard.dispatch_trace_to_markdown(trace).contains("Dispatch replay"),
  )
}

///|
test "timeline records regression" {
  let clean = @moonkeyguard.analyze(
    @moonkeyguard.parse_keymap(@moonkeyguard.clean_demo_source()).keymap,
  )
  let bad = @moonkeyguard.demo_analysis()
  let timeline = @moonkeyguard.AuditTimeline::new("editor")
  let timeline = @moonkeyguard.timeline_record_gate(
    timeline, "clean", "ci", clean,
  )
  let timeline = @moonkeyguard.timeline_record_gate(timeline, "bad", "ci", bad)
  assert_eq(timeline.events.length(), 2)
  assert_eq(@moonkeyguard.timeline_regressions(timeline).length(), 1)
  assert_true(
    @moonkeyguard.timeline_summary(timeline).contains("regressions=1"),
  )
}

///|
test "timeline json is append-only" {
  let timeline = @moonkeyguard.timeline_append(
    @moonkeyguard.AuditTimeline::new("x"),
    "import",
    "maintainer",
    Imported,
    @moonkeyguard.analyze(
      @moonkeyguard.parse_keymap(@moonkeyguard.clean_demo_source()).keymap,
    ),
    note="source",
  )
  assert_eq(@moonkeyguard.timeline_latest(timeline).unwrap().sequence, 1)
  assert_true(@moonkeyguard.timeline_to_json(timeline).contains("source"))
}

///|
test "catalog validates and explains" {
  let rules = @moonkeyguard.default_reserved_rules()
  assert_eq(@moonkeyguard.validate_catalog(rules).length(), 0)
  let binding = @moonkeyguard.demo_keymap().bindings.filter(item => {
      item.id == "quit"
    })[0]
  assert_true(@moonkeyguard.explain_reserved(binding, rules).length() > 0)
  let catalog = @moonkeyguard.audit_with_catalog(
    @moonkeyguard.demo_keymap(),
    rules,
  )
  assert_true(catalog.matched.length() > 0)
  assert_true(
    @moonkeyguard.catalog_report_to_markdown(catalog).contains(
      "Reservation catalog",
    ),
  )
}

///|
test "catalog can be applied" {
  let keymap = @moonkeyguard.apply_reserved_catalog(
    @moonkeyguard.Keymap::empty(),
    @moonkeyguard.default_reserved_rules(),
  )
  assert_true(keymap.reserved.length() > 10)
  assert_true(
    @moonkeyguard.catalog_to_json(@moonkeyguard.default_reserved_rules()).contains(
      "platform",
    ),
  )
}

///|
test "structural validator catches cycles" {
  let source =
    #|context a parent=b rank=1
    #|context b parent=a rank=1
    #|bind x command=bad keys=Ctrl+X context=a
  let report = @moonkeyguard.validate_keymap(
    @moonkeyguard.parse_keymap(source).keymap,
  )
  assert_false(report.valid)
  assert_true(
    report.issues.filter(item => item.kind == ContextCycle).length() > 0,
  )
  assert_true(@moonkeyguard.validation_to_markdown(report).contains("INVALID"))
}

///|
test "structural validator recommends descriptions" {
  let report = @moonkeyguard.validate_keymap(
    @moonkeyguard.parse_keymap("bind x command=good keys=Ctrl+X").keymap,
  )
  assert_true(report.warning_count > 0)
  assert_true(
    @moonkeyguard.validation_to_json(report).contains("empty-description"),
  )
}

///|
test "benchmark fixture is deterministic" {
  let fixture = @moonkeyguard.benchmark_case(
    "dispatch",
    ["Ctrl+S", "Ctrl+K", "Ctrl+Z"],
    context="editor",
    expected_status=NoMatch,
    repetitions=2,
  )
  let result = @moonkeyguard.run_benchmark(@moonkeyguard.demo_keymap(), fixture)
  assert_eq(result.operations, 6)
  assert_true(result.score <= 100)
  assert_true(
    @moonkeyguard.benchmark_result_to_json(result).contains("operations"),
  )
}

///|
test "complexity report documents hot paths" {
  let report = @moonkeyguard.complexity_report(
    @moonkeyguard.demo_keymap(),
    @moonkeyguard.demo_analysis(),
  )
  assert_true(report.analysis_complexity.contains("bindings"))
  assert_true(
    @moonkeyguard.complexity_to_markdown(report).contains("Memory notes"),
  )
}

///|
test "project rules enforce prefix and modifier" {
  let rules = {
    ..@moonkeyguard.ProjectRules::default(),
    command_prefix: "app.",
    require_modifier: true,
    allowed_platforms: ["mac"],
  }
  let report = @moonkeyguard.evaluate_project_rules(
    @moonkeyguard.parse_keymap("bind x command=bad keys=F6 platform=linux").keymap,
    rules,
  )
  assert_false(report.passed)
  assert_eq(report.findings.length(), 3)
  assert_true(
    @moonkeyguard.rule_report_to_markdown(report).contains("Project rule"),
  )
}

///|
test "rules integrate into analysis" {
  let rules = {
    ..@moonkeyguard.ProjectRules::default(),
    require_description: true,
  }
  let analysis = @moonkeyguard.analyze_with_rules(
    @moonkeyguard.parse_keymap("bind x command=app.x keys=Ctrl+X").keymap,
    rules,
  )
  assert_true(analysis.warning_count > 0)
  assert_true(
    @moonkeyguard.rule_report_to_json(
      @moonkeyguard.evaluate_project_rules(
        @moonkeyguard.parse_keymap("bind x command=app.x keys=Ctrl+X").keymap,
        rules,
      ),
    ).contains("findings"),
  )
}

///|
test "recommendations are prioritized" {
  let items = @moonkeyguard.health_recommendations(
    @moonkeyguard.demo_keymap(),
    @moonkeyguard.demo_analysis(),
  )
  assert_true(items.length() > 0)
  assert_true(items[0].priority <= items[items.length() - 1].priority)
  assert_true(
    @moonkeyguard.recommendations_to_markdown(items).contains(
      "Recommended actions",
    ),
  )
  assert_true(@moonkeyguard.recommendations_to_json(items).has_prefix("["))
}

///|
test "project capabilities stay explicit" {
  let capabilities = @moonkeyguard.project_capabilities()
  assert_true(capabilities.length() >= 6)
  assert_true(
    capabilities.filter(item => item.contains("conflict")).length() == 1,
  )
}
