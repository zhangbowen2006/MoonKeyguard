///|
test "baseline accepts unchanged findings" {
  let analysis = demo_analysis()
  let report = compare_baseline(analysis, analysis)
  assert_true(report.passed)
  assert_eq(report.new_findings.length(), 0)
  assert_eq(report.retained_count, analysis.findings.length())
}

///|
test "baseline blocks newly introduced errors" {
  let baseline = analyze(parse_keymap(clean_demo_source()).keymap)
  let current = demo_analysis()
  let report = compare_baseline(baseline, current)
  assert_false(report.passed)
  assert_true(report.new_error_count > 0)
  assert_true(report.new_findings.length() > 0)
}

///|
test "baseline can ratchet warnings" {
  let baseline = analyze(parse_keymap(clean_demo_source()).keymap)
  let current = analyze(
    parse_keymap(
      "bind first command=one keys=Ctrl+K\nbind second command=two keys=Ctrl+K,Ctrl+L",
    ).keymap,
  )
  let permissive = compare_baseline(baseline, current)
  assert_true(permissive.passed)
  assert_eq(permissive.new_warning_count, 1)
  let strict = compare_baseline(baseline, current, fail_on_warning=true)
  assert_false(strict.passed)
}

///|
test "baseline records resolved findings" {
  let report = compare_baseline(
    demo_analysis(),
    analyze(parse_keymap(clean_demo_source()).keymap),
  )
  assert_true(report.resolved_findings.length() > 0)
  assert_true(report.passed)
  assert_true(baseline_report_to_markdown(report).contains("Resolved findings"))
  assert_true(baseline_report_to_json(report).contains("resolved_count"))
}
