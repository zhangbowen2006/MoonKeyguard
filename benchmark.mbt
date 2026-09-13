///|
/// Portable benchmark and regression fixtures without wall-clock dependence.
pub(all) struct BenchmarkCase {
  name : String
  inputs : Array[String]
  context : String
  platform : String
  expected_status : DispatchStatus
  repetitions : Int
} derive(Eq, @debug.Debug)

///|
pub(all) struct BenchmarkResult {
  name : String
  operations : Int
  matched : Int
  prefixes : Int
  misses : Int
  mismatches : Int
  score : Int
  notes : Array[String]
} derive(Eq, @debug.Debug)

///|
pub(all) struct ComplexityReport {
  bindings : Int
  contexts : Int
  findings : Int
  parse_complexity : String
  analysis_complexity : String
  dispatch_complexity : String
  memory_notes : Array[String]
} derive(Eq, @debug.Debug)

///|
pub fn benchmark_case(
  name : String,
  inputs : Array[String],
  context? : String = "global",
  platform? : String = "all",
  expected_status? : DispatchStatus = Matched,
  repetitions? : Int = 1,
) -> BenchmarkCase {
  {
    name,
    inputs,
    context,
    platform,
    expected_status,
    repetitions: if repetitions < 1 {
      1
    } else {
      repetitions
    },
  }
}

///|
/// Run a deterministic benchmark fixture and report semantic mismatches.
pub fn run_benchmark(
  keymap : Keymap,
  fixture : BenchmarkCase,
) -> BenchmarkResult {
  let mut operations = 0
  let mut matched = 0
  let mut prefixes = 0
  let mut misses = 0
  let mut mismatches = 0
  for _ in 0..<fixture.repetitions {
    for input in fixture.inputs {
      let result = dispatch(
        keymap,
        input,
        context=fixture.context,
        platform=fixture.platform,
      )
      operations += 1
      match result.status {
        Matched => matched += 1
        Prefix => prefixes += 1
        _ => misses += 1
      }
      if result.status != fixture.expected_status {
        mismatches += 1
      }
    }
  }
  let score = if operations == 0 {
    100
  } else {
    100 - mismatches * 100 / operations
  }
  let notes : Array[String] = []
  if mismatches > 0 {
    notes.push("fixture expectation differs from dispatcher output")
  }
  if prefixes > 0 {
    notes.push("prefix states require a timeout-aware UI dispatcher")
  }
  {
    name: fixture.name,
    operations,
    matched,
    prefixes,
    misses,
    mismatches,
    score,
    notes,
  }
}

///|
pub fn benchmark_suite(
  keymap : Keymap,
  fixtures : Array[BenchmarkCase],
) -> Array[BenchmarkResult] {
  let result : Array[BenchmarkResult] = []
  for fixture in fixtures {
    result.push(run_benchmark(keymap, fixture))
  }
  result
}

///|
pub fn benchmark_result_to_json(result : BenchmarkResult) -> String {
  let notes : Array[String] = []
  for note in result.notes {
    notes.push(json_string(note))
  }
  "{\"name\":" +
  json_string(result.name) +
  ",\"operations\":" +
  result.operations.to_string() +
  ",\"matched\":" +
  result.matched.to_string() +
  ",\"prefixes\":" +
  result.prefixes.to_string() +
  ",\"misses\":" +
  result.misses.to_string() +
  ",\"mismatches\":" +
  result.mismatches.to_string() +
  ",\"score\":" +
  result.score.to_string() +
  ",\"notes\":[" +
  notes.join(",") +
  "]}"
}

///|
pub fn benchmark_results_to_markdown(
  results : Array[BenchmarkResult],
) -> String {
  let lines : Array[String] = [
    "## Dispatcher benchmark", "", "| Fixture | Operations | Matched | Prefix | Misses | Mismatches | Score |",
    "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
  ]
  for result in results {
    lines.push(
      "| " +
      result.name +
      " | " +
      result.operations.to_string() +
      " | " +
      result.matched.to_string() +
      " | " +
      result.prefixes.to_string() +
      " | " +
      result.misses.to_string() +
      " | " +
      result.mismatches.to_string() +
      " | " +
      result.score.to_string() +
      " |",
    )
  }
  lines.join("\n")
}

///|
/// Explain the current implementation's asymptotic behavior so it can be
/// tracked when a future indexed implementation is introduced.
pub fn complexity_report(
  keymap : Keymap,
  analysis : Analysis,
) -> ComplexityReport {
  {
    bindings: keymap.bindings.length(),
    contexts: keymap.contexts.length(),
    findings: analysis.findings.length(),
    parse_complexity: "O(lines × attributes)",
    analysis_complexity: "O(bindings² + bindings × context-depth)",
    dispatch_complexity: "O(bindings × context-depth)",
    memory_notes: [
      "parser stores one owned string per attribute", "analysis retains findings for review and CI annotations",
      "conflict graph adds one edge per pair finding",
    ],
  }
}

///|
pub fn complexity_to_markdown(report : ComplexityReport) -> String {
  let lines : Array[String] = [
    "## Complexity profile",
    "",
    "- bindings: " + report.bindings.to_string(),
    "- contexts: " + report.contexts.to_string(),
    "- findings: " + report.findings.to_string(),
    "- parser: `" + report.parse_complexity + "`",
    "- analysis: `" + report.analysis_complexity + "`",
    "- dispatch: `" + report.dispatch_complexity + "`",
    "",
    "### Memory notes",
  ]
  for note in report.memory_notes {
    lines.push("- " + note)
  }
  lines.join("\n")
}
