///|
/// Named policy profiles turn the analyzer into a repeatable CI gate.
pub(all) struct PolicyProfile {
  name : String
  reserved : Array[String]
  max_chord_length : Int
  max_modifier_count : Int
  require_description : Bool
  allow_disabled : Bool
  fail_on_warning : Bool
  allowed_platforms : Array[String]
} derive(Eq, @debug.Debug)

///|
pub(all) struct ProfileReport {
  profile : PolicyProfile
  parse : ParseResult
  analysis : Analysis
  metrics : KeymapMetrics
  passed : Bool
  gate_messages : Array[String]
} derive(Eq, @debug.Debug)

///|
fn profile(
  name : String,
  reserved : Array[String],
  max_chord_length : Int,
  max_modifier_count : Int,
  require_description : Bool,
  allow_disabled : Bool,
  fail_on_warning : Bool,
  allowed_platforms : Array[String],
) -> PolicyProfile {
  {
    name,
    reserved,
    max_chord_length,
    max_modifier_count,
    require_description,
    allow_disabled,
    fail_on_warning,
    allowed_platforms,
  }
}

///|
/// Sensible cross-platform defaults for desktop applications.
pub fn desktop_profile() -> PolicyProfile {
  profile(
    "desktop",
    ["all:Ctrl+Alt+Delete", "all:Cmd+Q", "all:Alt+F4"],
    3,
    3,
    true,
    true,
    false,
    ["all", "windows", "mac", "linux"],
  )
}

///|
/// A stricter profile for terminal and shell applications.
pub fn terminal_profile() -> PolicyProfile {
  profile(
    "terminal",
    ["all:Ctrl+C", "all:Ctrl+D", "all:Ctrl+Z", "all:Ctrl+\\"],
    2,
    2,
    true,
    false,
    true,
    ["all", "windows", "mac", "linux", "freebsd"],
  )
}

///|
/// A profile for user-facing tools that prioritizes discoverability.
pub fn accessible_profile() -> PolicyProfile {
  profile(
    "accessible",
    ["all:Ctrl+Alt+Delete", "all:Cmd+Q", "all:Alt+F4"],
    2,
    2,
    true,
    false,
    true,
    ["all", "windows", "mac", "linux"],
  )
}

///|
/// Resolve the built-in profile by name.
pub fn profile_by_name(name : String) -> PolicyProfile {
  match lower_ascii(name) {
    "terminal" => terminal_profile()
    "accessible" => accessible_profile()
    "strict" => {
      let base = accessible_profile()
      {
        ..base,
        name: "strict",
        max_chord_length: 1,
        max_modifier_count: 2,
        require_description: true,
      }
    }
    _ => desktop_profile()
  }
}

///|
fn profile_reserved(keymap : Keymap, profile : PolicyProfile) -> Keymap {
  let markers = keymap.reserved.copy()
  for marker in profile.reserved {
    if !array_contains(markers, marker) {
      markers.push(marker)
    }
  }
  { ..keymap, reserved: markers, }
}

///|
fn profile_finding(
  code : String,
  kind : IssueKind,
  severity : Severity,
  message : String,
  binding : Binding,
  suggestion : String,
) -> Finding {
  {
    code,
    kind,
    severity,
    message,
    primary_id: binding.id,
    secondary_id: "",
    shortcut: binding.keys.canonical,
    context: binding.context,
    source: binding.source,
    line: binding.line,
    suggestion,
  }
}

///|
fn profile_findings(keymap : Keymap, profile : PolicyProfile) -> Array[Finding] {
  let result : Array[Finding] = []
  for binding in keymap.bindings {
    if profile.require_description && binding.description.length() == 0 {
      result.push(
        profile_finding(
          "MK501",
          InvalidRecord,
          Warning,
          "binding has no description under the selected policy profile",
          binding,
          "describe the user-visible action and its scope",
        ),
      )
    }
    if binding.keys.steps.length() > profile.max_chord_length {
      result.push(
        profile_finding(
          "MK502",
          AccessibilityRisk,
          Warning,
          "chord is longer than the profile limit",
          binding,
          "shorten the chord or document a command-palette fallback",
        ),
      )
    }
    if binding.keys.modifier_count > profile.max_modifier_count {
      result.push(
        profile_finding(
          "MK503",
          AccessibilityRisk,
          Warning,
          "modifier count exceeds the profile limit",
          binding,
          "reduce modifiers and keep a discoverable alternative",
        ),
      )
    }
    if !profile.allow_disabled && !binding.enabled {
      result.push(
        profile_finding(
          "MK504",
          DisabledBinding,
          Warning,
          "disabled binding is not allowed in this release profile",
          binding,
          "remove the entry or move it to a migration-only keymap",
        ),
      )
    }
    if profile.allowed_platforms.length() > 0 &&
      !platform_contains_any(profile.allowed_platforms, binding.platform) {
      result.push(
        profile_finding(
          "MK505",
          InvalidRecord,
          Error,
          "binding targets a platform outside the profile allow-list",
          binding,
          "use one of the declared platforms or split the keymap",
        ),
      )
    }
  }
  result
}

///|
fn platform_contains_any(allowed : Array[String], platform : String) -> Bool {
  for item in allowed {
    if platforms_overlap(item, platform) {
      return true
    }
  }
  false
}

///|
fn append_findings(analysis : Analysis, extra : Array[Finding]) -> Analysis {
  let findings = analysis.findings.copy()
  for item in extra {
    findings.push(item)
  }
  let errors = count_severity(findings, Error)
  let warnings = count_severity(findings, Warning)
  let infos = count_severity(findings, Info)
  {
    ..analysis,
    findings,
    error_count: errors,
    warning_count: warnings,
    info_count: infos,
    score: score_findings(findings),
  }
}

///|
/// Analyze one source document with a named policy profile.
pub fn audit_with_profile(
  source : String,
  name : String,
  profile : PolicyProfile,
) -> ProfileReport {
  let parsed = parse_keymap(source, name~)
  let scoped = profile_reserved(parsed.keymap, profile)
  let base = analyze(scoped)
  let analysis = append_findings(base, profile_findings(scoped, profile))
  let metrics = keymap_metrics(scoped)
  let gate_messages : Array[String] = []
  if parsed.diagnostics.length() > 0 {
    gate_messages.push("parser diagnostics present")
  }
  if analysis.error_count > 0 {
    gate_messages.push(analysis.error_count.to_string() + " error findings")
  }
  if profile.fail_on_warning && analysis.warning_count > 0 {
    gate_messages.push("warnings are fatal in profile " + profile.name)
  }
  let passed = parsed.ok &&
    analysis.error_count == 0 &&
    (!profile.fail_on_warning || analysis.warning_count == 0)
  { profile, parse: parsed, analysis, metrics, passed, gate_messages, }
}

///|
/// Convenience overload using a built-in profile.
pub fn audit_with_named_profile(
  source : String,
  name : String,
  profile_name : String,
) -> ProfileReport {
  audit_with_profile(source, name, profile_by_name(profile_name))
}

///|
pub fn profile_report_to_json(report : ProfileReport) -> String {
  let gates : Array[String] = []
  for message in report.gate_messages {
    gates.push(json_string(message))
  }
  "{\"profile\":" +
  json_string(report.profile.name) +
  ",\"passed\":" +
  (if report.passed { "true" } else { "false" }) +
  ",\"analysis\":" +
  analysis_to_json(report.analysis) +
  ",\"metrics\":" +
  metrics_to_json(report.metrics) +
  ",\"gates\":[" +
  gates.join(",") +
  "]}"
}

///|
pub fn profile_report_to_markdown(report : ProfileReport) -> String {
  let lines : Array[String] = [
    "## Policy profile: " + report.profile.name,
    "",
    "Result: **" + (if report.passed { "PASS" } else { "FAIL" }) + "**",
    "",
    analysis_to_markdown(report.analysis),
    "",
    "### Gate messages",
  ]
  if report.gate_messages.length() == 0 {
    lines.push("- none")
  } else {
    for message in report.gate_messages {
      lines.push("- " + message)
    }
  }
  lines.join("\n")
}
