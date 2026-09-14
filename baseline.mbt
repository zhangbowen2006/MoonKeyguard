///|
/// A finding identity that is stable across line moves and message wording.
fn baseline_finding_key(finding : Finding) -> String {
  finding.code +
  "|" +
  finding.kind.name() +
  "|" +
  finding.primary_id +
  "|" +
  finding.secondary_id +
  "|" +
  finding.shortcut +
  "|" +
  finding.context
}

///|
fn baseline_contains(findings : Array[Finding], target : Finding) -> Bool {
  let key = baseline_finding_key(target)
  for finding in findings {
    if baseline_finding_key(finding) == key {
      return true
    }
  }
  false
}

///|
fn baseline_count(findings : Array[Finding], severity : Severity) -> Int {
  findings.filter(item => item.severity == severity).length()
}

///|
/// A differential report for CI baseline checks.
///
/// Existing findings are retained as debt, while only newly introduced
/// findings affect the default gate. Finding identities deliberately omit line
/// and source so that moving a declaration does not look like a new defect.
pub(all) struct BaselineReport {
  baseline_fingerprint : String
  current_fingerprint : String
  baseline_count : Int
  current_count : Int
  new_findings : Array[Finding]
  resolved_findings : Array[Finding]
  retained_count : Int
  new_error_count : Int
  new_warning_count : Int
  new_info_count : Int
  fail_on_warning : Bool
  passed : Bool
} derive(Eq, @debug.Debug)

///|
/// Compare a current analysis with an accepted baseline.
///
/// By default this is a ratchet: old findings remain visible but do not block
/// a release, while any new error blocks it. Set `fail_on_warning` when a team
/// wants warnings to be part of its release policy as well.
pub fn compare_baseline(
  baseline : Analysis,
  current : Analysis,
  fail_on_warning? : Bool = false,
) -> BaselineReport {
  let new_findings : Array[Finding] = []
  let resolved_findings : Array[Finding] = []
  let mut retained = 0
  for finding in current.findings {
    if baseline_contains(baseline.findings, finding) {
      retained += 1
    } else {
      new_findings.push(finding)
    }
  }
  for finding in baseline.findings {
    if !baseline_contains(current.findings, finding) {
      resolved_findings.push(finding)
    }
  }
  let new_errors = baseline_count(new_findings, Error)
  let new_warnings = baseline_count(new_findings, Warning)
  let new_infos = baseline_count(new_findings, Info)
  {
    baseline_fingerprint: baseline.fingerprint,
    current_fingerprint: current.fingerprint,
    baseline_count: baseline.findings.length(),
    current_count: current.findings.length(),
    new_findings,
    resolved_findings,
    retained_count: retained,
    new_error_count: new_errors,
    new_warning_count: new_warnings,
    new_info_count: new_infos,
    fail_on_warning,
    passed: new_errors == 0 && (!fail_on_warning || new_warnings == 0),
  }
}

///|
/// Return a concise baseline summary for CI logs.
pub fn BaselineReport::summary(self : BaselineReport) -> String {
  "baseline=" +
  self.baseline_count.to_string() +
  " current=" +
  self.current_count.to_string() +
  " new=" +
  self.new_findings.length().to_string() +
  " resolved=" +
  self.resolved_findings.length().to_string() +
  " retained=" +
  self.retained_count.to_string() +
  " result=" +
  (if self.passed { "pass" } else { "fail" })
}

///|
/// Render a baseline report as Markdown suitable for a pull request comment.
pub fn baseline_report_to_markdown(report : BaselineReport) -> String {
  let lines : Array[String] = [
    "## Baseline gate",
    "",
    "Result: **" + (if report.passed { "PASS" } else { "FAIL" }) + "**",
    "",
    "| Metric | Value |",
    "| --- | ---: |",
    "| Baseline findings | " + report.baseline_count.to_string() + " |",
    "| Current findings | " + report.current_count.to_string() + " |",
    "| New findings | " + report.new_findings.length().to_string() + " |",
    "| Resolved findings | " +
    report.resolved_findings.length().to_string() +
    " |",
    "| Retained findings | " + report.retained_count.to_string() + " |",
    "| New errors | " + report.new_error_count.to_string() + " |",
    "| New warnings | " + report.new_warning_count.to_string() + " |",
  ]
  if report.new_findings.length() > 0 {
    lines.push("")
    lines.push("### New findings")
    for finding in report.new_findings {
      lines.push("- `" + finding.code + "` " + finding.to_line())
    }
  }
  lines.join("\n")
}

///|
/// Serialize a baseline result for CI artifacts.
pub fn baseline_report_to_json(report : BaselineReport) -> String {
  let new_rows : Array[String] = []
  for finding in report.new_findings {
    new_rows.push(
      "{\"code\":" +
      json_string(finding.code) +
      ",\"kind\":" +
      json_string(finding.kind.name()) +
      ",\"severity\":" +
      json_string(finding.severity.name()) +
      ",\"id\":" +
      json_string(finding.primary_id) +
      "}",
    )
  }
  "{\"baseline_fingerprint\":" +
  json_string(report.baseline_fingerprint) +
  ",\"current_fingerprint\":" +
  json_string(report.current_fingerprint) +
  ",\"baseline_count\":" +
  report.baseline_count.to_string() +
  ",\"current_count\":" +
  report.current_count.to_string() +
  ",\"new_count\":" +
  report.new_findings.length().to_string() +
  ",\"resolved_count\":" +
  report.resolved_findings.length().to_string() +
  ",\"retained_count\":" +
  report.retained_count.to_string() +
  ",\"new_errors\":" +
  report.new_error_count.to_string() +
  ",\"new_warnings\":" +
  report.new_warning_count.to_string() +
  ",\"new_infos\":" +
  report.new_info_count.to_string() +
  ",\"fail_on_warning\":" +
  (if report.fail_on_warning { "true" } else { "false" }) +
  ",\"passed\":" +
  (if report.passed { "true" } else { "false" }) +
  ",\"new_findings\":[" +
  new_rows.join(",") +
  "]}"
}
