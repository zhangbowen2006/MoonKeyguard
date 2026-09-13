///|
/// Deterministic text, JSON, Markdown and SARIF renderers.
fn json_escape(value : String) -> String {
  let out = StringBuilder()
  for c in value {
    match c {
      '"' => out.write_string("\\\"")
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(c)
    }
  }
  out.to_string()
}

///|
fn json_string(value : String) -> String {
  "\"" + json_escape(value) + "\""
}

///|
fn finding_json(finding : Finding) -> String {
  "{" +
  "\"code\":" +
  json_string(finding.code) +
  "," +
  "\"kind\":" +
  json_string(finding.kind.name()) +
  "," +
  "\"severity\":" +
  json_string(finding.severity.name()) +
  "," +
  "\"message\":" +
  json_string(finding.message) +
  "," +
  "\"primary\":" +
  json_string(finding.primary_id) +
  "," +
  "\"secondary\":" +
  json_string(finding.secondary_id) +
  "," +
  "\"shortcut\":" +
  json_string(finding.shortcut) +
  "," +
  "\"context\":" +
  json_string(finding.context) +
  "," +
  "\"source\":" +
  json_string(finding.source) +
  "," +
  "\"line\":" +
  finding.line.to_string() +
  "," +
  "\"suggestion\":" +
  json_string(finding.suggestion) +
  "}"
}

///|
/// Serialize an analysis without relying on a third-party JSON package.
pub fn analysis_to_json(analysis : Analysis) -> String {
  let findings : Array[String] = []
  for item in analysis.findings {
    findings.push(finding_json(item))
  }
  let ok = if analysis.ok() { "true" } else { "false" }
  "{" +
  "\"keymap\":" +
  json_string(analysis.keymap_name) +
  "," +
  "\"checked_bindings\":" +
  analysis.checked_bindings.to_string() +
  "," +
  "\"enabled_bindings\":" +
  analysis.enabled_bindings.to_string() +
  "," +
  "\"errors\":" +
  analysis.error_count.to_string() +
  "," +
  "\"warnings\":" +
  analysis.warning_count.to_string() +
  "," +
  "\"infos\":" +
  analysis.info_count.to_string() +
  "," +
  "\"score\":" +
  analysis.score.to_string() +
  "," +
  "\"fingerprint\":" +
  json_string(analysis.fingerprint) +
  "," +
  "\"ok\":" +
  ok +
  "," +
  "\"findings\":[" +
  findings.join(",") +
  "]" +
  "}"
}

///|
/// Serialize parser diagnostics for CI consumers.
pub fn parse_diagnostics_to_json(
  diagnostics : Array[ParseDiagnostic],
) -> String {
  let rows : Array[String] = []
  for diagnostic in diagnostics {
    rows.push(
      "{" +
      "\"line\":" +
      diagnostic.line.to_string() +
      "," +
      "\"code\":" +
      json_string(diagnostic.code) +
      "," +
      "\"message\":" +
      json_string(diagnostic.message) +
      "," +
      "\"source\":" +
      json_string(diagnostic.source) +
      "}",
    )
  }
  "[" + rows.join(",") + "]"
}

///|
/// Human-readable report suitable for a pull request comment.
pub fn analysis_to_text(analysis : Analysis) -> String {
  let lines : Array[String] = [
    "MoonKeyguard analysis",
    "======================",
    analysis.summary(),
  ]
  if analysis.findings.length() == 0 {
    lines.push("No findings. The keymap is internally consistent.")
  } else {
    lines.push("")
    for item in analysis.findings {
      lines.push(item.to_line())
      if item.suggestion.length() > 0 {
        lines.push("  suggestion: " + item.suggestion)
      }
    }
  }
  lines.join("\n")
}

///|
/// Render a concise Markdown table for documentation and release notes.
pub fn analysis_to_markdown(analysis : Analysis) -> String {
  let lines : Array[String] = [
    "## MoonKeyguard report",
    "",
    "| Metric | Value |",
    "| --- | ---: |",
    "| Keymap | " + analysis.keymap_name + " |",
    "| Checked bindings | " + analysis.checked_bindings.to_string() + " |",
    "| Enabled bindings | " + analysis.enabled_bindings.to_string() + " |",
    "| Errors | " + analysis.error_count.to_string() + " |",
    "| Warnings | " + analysis.warning_count.to_string() + " |",
    "| Score | " + analysis.score.to_string() + "/100 |",
    "| Fingerprint | `" + analysis.fingerprint + "` |",
    "",
    "| Severity | Code | Shortcut | Context | Message |",
    "| --- | --- | --- | --- | --- |",
  ]
  for item in analysis.findings {
    lines.push(
      "| " +
      item.severity.name() +
      " | " +
      item.code +
      " | `" +
      item.shortcut +
      "` | `" +
      item.context +
      "` | " +
      item.message +
      " |",
    )
  }
  lines.join("\n")
}

///|
fn sarif_level(severity : Severity) -> String {
  match severity {
    Error => "error"
    Warning => "warning"
    Info => "note"
  }
}

///|
fn finding_sarif(finding : Finding) -> String {
  let location = if finding.source.length() == 0 {
    ""
  } else {
    ",\"locations\":[{\"physicalLocation\":{\"artifactLocation\":{\"uri\":" +
    json_string(finding.source) +
    "},\"region\":{\"startLine\":" +
    finding.line.to_string() +
    "}}}]"
  }
  "{" +
  "\"ruleId\":" +
  json_string(finding.code) +
  "," +
  "\"level\":" +
  json_string(sarif_level(finding.severity)) +
  "," +
  "\"message\":{\"text\":" +
  json_string(finding.message) +
  "}" +
  location +
  "}"
}

///|
/// SARIF 2.1.0 output lets GitHub annotate keymap files in CI.
pub fn analysis_to_sarif(analysis : Analysis) -> String {
  let results : Array[String] = []
  for item in analysis.findings {
    results.push(finding_sarif(item))
  }
  "{\"version\":\"2.1.0\",\"$schema\":\"https://json.schemastore.org/sarif-2.1.0.json\",\"runs\":[{\"tool\":{\"driver\":{\"name\":\"MoonKeyguard\",\"version\":\"0.1.0\"}},\"results\":[" +
  results.join(",") +
  "]}]}"
}

///|
/// Return a conventional process exit code for a CI gate.
pub fn analysis_exit_code(
  analysis : Analysis,
  fail_on_warning? : Bool = false,
) -> Int {
  if analysis.error_count > 0 || (fail_on_warning && analysis.warning_count > 0) {
    1
  } else {
    0
  }
}
