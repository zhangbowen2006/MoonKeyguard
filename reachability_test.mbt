///|
test "reachability matrix identifies winner and shadowed binding" {
  let source =
    #|context editor parent=global rank=10 description=editor
    #|bind global_save command=save keys=Ctrl+S context=global priority=1 description=global
    #|bind editor_save command=save keys=Ctrl+S context=editor priority=5 description=editor
    #|bind disabled command=old keys=Alt+O enabled=false description=legacy
  let keymap = parse_keymap(source).keymap
  let report = reachability_matrix(keymap, contexts=["editor", "global"], platforms=[
    "all",
  ])
  assert_eq(report.binding_count, 3)
  assert_eq(report.reachable_count, 2)
  assert_eq(report.shadowed_count, 1)
  assert_eq(report.disabled_count, 2)
  assert_true(reachability_to_markdown(report).contains("shadowed"))
}

///|
test "reachability reports ambiguous equal priority declarations" {
  let source =
    #|bind first command=one keys=Ctrl+X priority=1 description=one
    #|bind second command=two keys=Ctrl+X priority=1 description=two
  let keymap = parse_keymap(source).keymap
  let report = reachability_matrix(keymap)
  assert_eq(report.ambiguous_count, 2)
  assert_true(reachability_to_json(report).contains("ambiguous"))
}

///|
test "reachability probes are deduplicated and sorted" {
  let source =
    #|context z parent=global rank=1 description=z
    #|context a parent=global rank=1 description=a
    #|bind x command=x keys=F6 description=x
  let keymap = parse_keymap(source).keymap
  let report = reachability_matrix(keymap, contexts=["z", "a", "z"], platforms=[
    "Linux", "all", "Linux",
  ])
  assert_eq(report.contexts, ["a", "z"])
  assert_eq(report.platforms, ["all", "linux"])
  assert_eq(report.cells.length(), 4)
}

///|
test "reachability marks declarations outside requested scope unavailable" {
  let source =
    #|context editor parent=global rank=1 description=editor
    #|bind editor_only command=x keys=F6 context=editor platform=mac description=x
  let keymap = parse_keymap(source).keymap
  let report = reachability_matrix(keymap, contexts=["global"], platforms=[
    "linux",
  ])
  assert_eq(report.unavailable_count, 1)
  assert_eq(report.reachable_count, 0)
}
