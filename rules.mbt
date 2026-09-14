///|
/// Extensible project rules for teams that need conventions beyond built-ins.
pub(all) struct ProjectRules {
  command_prefix : String
  required_contexts : Array[String]
  allowed_platforms : Array[String]
  max_bindings_per_context : Int
  require_modifier : Bool
  require_description : Bool
  fail_on_info : Bool
} derive(Eq, @debug.Debug)

///|
pub(all) struct RuleReport {
  rules : ProjectRules
  findings : Array[Finding]
  passed : Bool
} derive(Eq, @debug.Debug)

///|
pub fn ProjectRules::default() -> ProjectRules {
  {
    command_prefix: "",
    required_contexts: ["global"],
    allowed_platforms: ["all", "windows", "mac", "linux"],
    max_bindings_per_context: 0,
    require_modifier: false,
    require_description: false,
    fail_on_info: false,
  }
}

///|
fn rule_finding(
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
fn has_required_context(keymap : Keymap, required : String) -> Bool {
  context_exists(keymap, required)
}

///|
fn binding_count_for_context(keymap : Keymap, context : String) -> Int {
  let mut count = 0
  for binding in keymap.bindings {
    if binding.context == context {
      count += 1
    }
  }
  count
}

///|
/// Apply project-specific naming, scope, density, and documentation rules.
pub fn evaluate_project_rules(
  keymap : Keymap,
  rules : ProjectRules,
) -> RuleReport {
  let findings : Array[Finding] = []
  for required in rules.required_contexts {
    if !has_required_context(keymap, required) {
      let fallback = Binding::new(
        "__keymap__",
        "__keymap__",
        parse_keys("Ctrl+Shift+P").unwrap(),
      )
      findings.push(
        rule_finding(
          "PR001",
          InvalidContext,
          Error,
          "required context '" + required + "' is missing",
          fallback,
          "declare the required context",
        ),
      )
    }
  }
  for binding in keymap.bindings {
    if rules.command_prefix.length() > 0 &&
      !binding.command.has_prefix(rules.command_prefix) {
      findings.push(
        rule_finding(
          "PR002",
          InvalidRecord,
          Warning,
          "command does not use the required project prefix",
          binding,
          "rename command to start with '" + rules.command_prefix + "'",
        ),
      )
    }
    if rules.allowed_platforms.length() > 0 &&
      !platform_contains_any(rules.allowed_platforms, binding.platform) {
      findings.push(
        rule_finding(
          "PR003",
          InvalidRecord,
          Error,
          "platform is not in the project allow-list",
          binding,
          "declare a supported platform",
        ),
      )
    }
    if rules.require_modifier && !binding.keys.has_modifier {
      findings.push(
        rule_finding(
          "PR004",
          AccessibilityRisk,
          Warning,
          "project rules require a modifier on every binding",
          binding,
          "add Ctrl, Cmd, Alt, or Shift",
        ),
      )
    }
    if rules.require_description && binding.description.length() == 0 {
      findings.push(
        rule_finding(
          "PR005",
          InvalidRecord,
          Warning,
          "project rules require a description",
          binding,
          "add description=...",
        ),
      )
    }
  }
  if rules.max_bindings_per_context > 0 {
    for context in keymap.contexts {
      let count = binding_count_for_context(keymap, context.name)
      if count > rules.max_bindings_per_context {
        let fallback = keymap.bindings.filter(binding => {
          binding.context == context.name
        })
        if fallback.length() > 0 {
          findings.push(
            rule_finding(
              "PR006",
              InvalidRecord,
              Warning,
              "context contains " +
              count.to_string() +
              " bindings, over the configured density limit",
              fallback[0],
              "split the context or document the interaction model",
            ),
          )
        }
      }
    }
  }
  let passed = findings.filter(item => item.severity == Error).length() == 0 &&
    (
      !rules.fail_on_info ||
      findings.filter(item => item.severity == Info).length() == 0
    )
  { rules, findings, passed }
}

///|
pub fn rule_report_to_json(report : RuleReport) -> String {
  let rows : Array[String] = []
  for finding in report.findings {
    rows.push(finding_json(finding))
  }
  "{\"passed\":" +
  (if report.passed { "true" } else { "false" }) +
  ",\"findings\":[" +
  rows.join(",") +
  "]}"
}

///|
pub fn rule_report_to_markdown(report : RuleReport) -> String {
  let lines : Array[String] = [
    "## Project rule report",
    "",
    "Passed: **" + (if report.passed { "yes" } else { "no" }) + "**",
    "",
  ]
  if report.findings.length() == 0 {
    lines.push("No project-specific rule findings.")
  } else {
    for finding in report.findings {
      lines.push("- " + finding.to_line())
    }
  }
  lines.join("\n")
}

///|
/// Combine built-in analysis with project rules while preserving evidence.
pub fn analyze_with_rules(keymap : Keymap, rules : ProjectRules) -> Analysis {
  let base = analyze(keymap)
  let extra = evaluate_project_rules(keymap, rules)
  append_findings(base, extra.findings)
}
