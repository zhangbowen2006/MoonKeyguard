///|
/// Release governance helpers keep the engineering evidence reviewable.
pub(all) struct GateItem {
  code : String
  title : String
  passed : Bool
  severity : Severity
  evidence : String
  remediation : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct ReleaseGate {
  project : String
  version : String
  items : Array[GateItem]
  passed : Bool
  score : Int
} derive(Eq, @debug.Debug)

///|
pub(all) struct ReleaseInput {
  keymap : Keymap
  analysis : Analysis
  validation : ValidationReport
  profile : ProfileReport?
  benchmark : Array[BenchmarkResult]
  diff : KeymapDiff?
} derive(Eq, @debug.Debug)

///|
fn gate_item(
  code : String,
  title : String,
  passed : Bool,
  severity : Severity,
  evidence : String,
  remediation : String,
) -> GateItem {
  { code, title, passed, severity, evidence, remediation, }
}

///|
fn benchmark_passed(results : Array[BenchmarkResult]) -> Bool {
  for result in results {
    if result.mismatches > 0 {
      return false
    }
  }
  true
}

///|
fn gate_score(items : Array[GateItem]) -> Int {
  if items.length() == 0 {
    return 100
  }
  let mut passed = 0
  for item in items {
    if item.passed {
      passed += 1
    }
  }
  passed * 100 / items.length()
}

///|
/// Evaluate the evidence that matters before publishing a new keymap policy.
pub fn release_gate(
  project : String,
  version : String,
  input : ReleaseInput,
) -> ReleaseGate {
  let items : Array[GateItem] = []
  items.push(
    gate_item(
      "RG001",
      "structural validation",
      input.validation.valid,
      Error,
      input.validation.error_count.to_string() + " structural errors",
      "fix invalid records, contexts, or reserved markers",
    ),
  )
  items.push(
    gate_item(
      "RG002",
      "conflict analysis",
      input.analysis.ok(),
      Error,
      input.analysis.error_count.to_string() + " error findings",
      "resolve exact conflicts and reserved shortcuts",
    ),
  )
  let profile_ok = match input.profile {
    Some(profile) => profile.passed
    None => true
  }
  items.push(
    gate_item(
      "RG003",
      "policy profile",
      profile_ok,
      Warning,
      if profile_ok {
        "profile passed"
      } else {
        "profile gate failed"
      },
      "adjust declarations or select a documented profile",
    ),
  )
  let bench_ok = benchmark_passed(input.benchmark)
  items.push(
    gate_item(
      "RG004",
      "dispatcher regression",
      bench_ok,
      Error,
      input.benchmark.length().to_string() + " benchmark fixtures",
      "update the dispatcher or expected fixture deliberately",
    ),
  )
  let diff_ok = match input.diff {
    None => true
    Some(diff) => behavioral_changes(diff).length() == 0
  }
  items.push(
    gate_item(
      "RG005",
      "migration review",
      diff_ok,
      Warning,
      if diff_ok {
        "no unreviewed behavior changes"
      } else {
        "behavioral changes present"
      },
      "review migration_plan output before release",
    ),
  )
  let passed = items
    .filter(item => !item.passed && item.severity == Error)
    .length() ==
    0
  { project, version, items, passed, score: gate_score(items), }
}

///|
fn gate_kind_name(severity : Severity) -> String {
  match severity {
    Error => "blocking"
    Warning => "advisory"
    Info => "informational"
  }
}

///|
pub fn release_gate_to_json(gate : ReleaseGate) -> String {
  let rows : Array[String] = []
  for item in gate.items {
    rows.push(
      "{\"code\":" +
      json_string(item.code) +
      ",\"title\":" +
      json_string(item.title) +
      ",\"passed\":" +
      (if item.passed { "true" } else { "false" }) +
      ",\"severity\":" +
      json_string(gate_kind_name(item.severity)) +
      ",\"evidence\":" +
      json_string(item.evidence) +
      ",\"remediation\":" +
      json_string(item.remediation) +
      "}",
    )
  }
  "{\"project\":" +
  json_string(gate.project) +
  ",\"version\":" +
  json_string(gate.version) +
  ",\"passed\":" +
  (if gate.passed { "true" } else { "false" }) +
  ",\"score\":" +
  gate.score.to_string() +
  ",\"items\":[" +
  rows.join(",") +
  "]}"
}

///|
pub fn release_gate_to_markdown(gate : ReleaseGate) -> String {
  let lines : Array[String] = [
    "## Release gate: " + gate.project + " " + gate.version,
    "",
    "Result: **" +
    (if gate.passed { "PASS" } else { "FAIL" }) +
    "** (score " +
    gate.score.to_string() +
    "/100)",
    "",
    "| Code | Check | Result | Severity | Evidence |",
    "| --- | --- | --- | --- | --- |",
  ]
  for item in gate.items {
    lines.push(
      "| `" +
      item.code +
      "` | " +
      item.title +
      " | " +
      (if item.passed { "pass" } else { "fail" }) +
      " | " +
      gate_kind_name(item.severity) +
      " | " +
      item.evidence +
      " |",
    )
  }
  lines.push("")
  lines.push("### Remediation")
  for item in gate.items {
    if !item.passed {
      lines.push("- `" + item.code + "`: " + item.remediation)
    }
  }
  lines.join("\n")
}

///|
/// Create a complete release input from a keymap and an optional baseline.
pub fn release_input(
  keymap : Keymap,
  profile? : PolicyProfile? = None,
  baseline? : Keymap? = None,
) -> ReleaseInput {
  let analysis = analyze(keymap)
  let validation = validate_keymap(keymap)
  let profile_report = match profile {
    Some(policy) =>
      Some(audit_with_profile(keymap_to_dsl(keymap), keymap.name, policy))
    None => None
  }
  let diff = match baseline {
    Some(previous) => Some(diff_keymaps(previous, keymap))
    None => None
  }
  {
    keymap,
    analysis,
    validation,
    profile: profile_report,
    benchmark: [],
    diff,
  }
}
