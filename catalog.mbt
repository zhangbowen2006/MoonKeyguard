///|
/// Curated reservation catalog with provenance-friendly explanations.
pub(all) struct ReservedRule {
  platform : String
  shortcut : String
  rationale : String
  source : String
  severity : Severity
} derive(Eq, @debug.Debug)

///|
pub(all) struct CatalogReport {
  keymap : Keymap
  matched : Array[ReservedRule]
  unmatched : Array[ReservedRule]
  findings : Array[Finding]
} derive(Eq, @debug.Debug)

///|
fn reserved_rule(
  platform : String,
  shortcut : String,
  rationale : String,
  source : String,
) -> ReservedRule {
  { platform, shortcut, rationale, source, severity: Error, }
}

///|
/// The catalog is intentionally conservative: it flags well-known system
/// controls, but the profile can always be customized for a product shell.
pub fn default_reserved_rules() -> Array[ReservedRule] {
  [
    reserved_rule(
      "all", "Ctrl+Alt+Delete", "system security screen on Windows", "Microsoft Windows documentation",
    ),
    reserved_rule(
      "windows", "Alt+F4", "close active window", "Microsoft Windows documentation",
    ),
    reserved_rule(
      "windows", "Win+L", "lock workstation", "Microsoft Windows documentation",
    ),
    reserved_rule(
      "windows", "Win+D", "show desktop", "Microsoft Windows documentation",
    ),
    reserved_rule(
      "windows", "Ctrl+Alt+Tab", "window switcher", "Microsoft Windows documentation",
    ),
    reserved_rule(
      "mac", "Cmd+Q", "quit foreground application", "Apple Human Interface Guidelines",
    ),
    reserved_rule(
      "mac", "Cmd+W", "close window or tab", "Apple Human Interface Guidelines",
    ),
    reserved_rule(
      "mac", "Cmd+Tab", "application switcher", "Apple Human Interface Guidelines",
    ),
    reserved_rule(
      "mac", "Cmd+Space", "system search", "Apple Human Interface Guidelines",
    ),
    reserved_rule(
      "mac", "Ctrl+Cmd+Q", "lock screen", "Apple Human Interface Guidelines",
    ),
    reserved_rule(
      "linux", "Alt+F4", "window manager close action", "freedesktop desktop conventions",
    ),
    reserved_rule(
      "linux", "Alt+Tab", "window manager switcher", "freedesktop desktop conventions",
    ),
    reserved_rule(
      "linux", "Ctrl+Alt+T", "terminal launcher convention", "freedesktop desktop conventions",
    ),
    reserved_rule(
      "linux", "Ctrl+Alt+L", "lock screen convention", "freedesktop desktop conventions",
    ),
    reserved_rule(
      "all", "Ctrl+C", "interrupt in terminal contexts", "POSIX terminal conventions",
    ),
    reserved_rule(
      "all", "Ctrl+D", "end-of-input in terminal contexts", "POSIX terminal conventions",
    ),
    reserved_rule(
      "all", "Ctrl+Z", "suspend foreground process", "POSIX terminal conventions",
    ),
    reserved_rule(
      "all", "Ctrl+\\", "quit foreground process", "POSIX terminal conventions",
    ),
    reserved_rule(
      "all", "Escape", "cancel or dismiss active interaction", "cross-platform interaction convention",
    ),
    reserved_rule(
      "all", "Tab", "focus traversal", "WCAG keyboard interaction guidance",
    ),
    reserved_rule(
      "all", "Shift+Tab", "reverse focus traversal", "WCAG keyboard interaction guidance",
    ),
    reserved_rule(
      "all", "Enter", "activate focused control", "WCAG keyboard interaction guidance",
    ),
    reserved_rule(
      "all", "Space", "activate focused control", "WCAG keyboard interaction guidance",
    ),
    reserved_rule(
      "all", "ArrowLeft", "spatial navigation", "WCAG keyboard interaction guidance",
    ),
    reserved_rule(
      "all", "ArrowRight", "spatial navigation", "WCAG keyboard interaction guidance",
    ),
    reserved_rule(
      "all", "ArrowUp", "spatial navigation", "WCAG keyboard interaction guidance",
    ),
    reserved_rule(
      "all", "ArrowDown", "spatial navigation", "WCAG keyboard interaction guidance",
    ),
    reserved_rule(
      "all", "F1", "help key convention", "desktop application conventions",
    ),
    reserved_rule(
      "all", "F10", "menu focus convention", "desktop application conventions",
    ),
    reserved_rule(
      "all", "F11", "fullscreen convention", "desktop application conventions",
    ),
  ]
}

///|
fn rule_matches(binding : Binding, rule : ReservedRule) -> Bool {
  binding.keys.canonical == canonical_keys(rule.shortcut) &&
  platforms_overlap(binding.platform, rule.platform)
}

///|
/// Find catalog rules that explain why a binding is reserved.
pub fn explain_reserved(
  binding : Binding,
  rules : Array[ReservedRule],
) -> Array[ReservedRule] {
  rules.filter(rule => rule_matches(binding, rule))
}

///|
fn catalog_finding(binding : Binding, rule : ReservedRule) -> Finding {
  {
    code: "MK410",
    kind: ReservedShortcut,
    severity: rule.severity,
    message: "catalog reserves " +
    rule.shortcut +
    " on " +
    rule.platform +
    ": " +
    rule.rationale,
    primary_id: binding.id,
    secondary_id: "",
    shortcut: binding.keys.canonical,
    context: binding.context,
    source: binding.source,
    line: binding.line,
    suggestion: "choose another chord or explicitly override this policy with a documented profile",
  }
}

///|
/// Audit against an explicit reservation catalog and preserve matched rules.
pub fn audit_with_catalog(
  keymap : Keymap,
  rules : Array[ReservedRule],
) -> CatalogReport {
  let matched : Array[ReservedRule] = []
  let findings : Array[Finding] = []
  for binding in keymap.bindings {
    for rule in explain_reserved(binding, rules) {
      if !array_contains(
          matched.map(item => item.platform + ":" + item.shortcut),
          rule.platform + ":" + rule.shortcut,
        ) {
        matched.push(rule)
      }
      findings.push(catalog_finding(binding, rule))
    }
  }
  let unmatched : Array[ReservedRule] = []
  for rule in rules {
    if !array_contains(
        matched.map(item => item.platform + ":" + item.shortcut),
        rule.platform + ":" + rule.shortcut,
      ) {
      unmatched.push(rule)
    }
  }
  { keymap, matched, unmatched, findings, }
}

///|
/// Add the catalog to a keymap's reserved markers without introducing dupes.
pub fn apply_reserved_catalog(
  keymap : Keymap,
  rules : Array[ReservedRule],
) -> Keymap {
  let result = keymap.reserved.copy()
  for rule in rules {
    let marker = lower_ascii(rule.platform) +
      ":" +
      canonical_keys(rule.shortcut)
    if !array_contains(result, marker) {
      result.push(marker)
    }
  }
  { ..keymap, reserved: result, }
}

///|
pub fn catalog_report_to_markdown(report : CatalogReport) -> String {
  let lines : Array[String] = [
    "## Reservation catalog report",
    "",
    "Matched rules: " + report.matched.length().to_string(),
    "Unmatched catalog rules: " + report.unmatched.length().to_string(),
    "",
    "| Binding | Shortcut | Reason | Source |",
    "| --- | --- | --- | --- |",
  ]
  for finding in report.findings {
    let reason = finding.message.replace(old="|", new="/")
    lines.push(
      "| `" +
      finding.primary_id +
      "` | `" +
      finding.shortcut +
      "` | " +
      reason +
      " | " +
      finding.source +
      " |",
    )
  }
  lines.join("\n")
}

///|
pub fn catalog_to_json(rules : Array[ReservedRule]) -> String {
  let rows : Array[String] = []
  for rule in rules {
    rows.push(
      "{\"platform\":" +
      json_string(rule.platform) +
      ",\"shortcut\":" +
      json_string(rule.shortcut) +
      ",\"rationale\":" +
      json_string(rule.rationale) +
      ",\"source\":" +
      json_string(rule.source) +
      "}",
    )
  }
  "[" + rows.join(",") + "]"
}

///|
/// Validate that every catalog entry itself uses a parseable shortcut.
pub fn validate_catalog(rules : Array[ReservedRule]) -> Array[String] {
  let errors : Array[String] = []
  for rule in rules {
    match parse_keys(rule.shortcut) {
      Ok(_) => ()
      Err(message) =>
        errors.push(rule.platform + ":" + rule.shortcut + " — " + message)
    }
  }
  errors
}
