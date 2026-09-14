///|
/// Structural validation runs before policy analysis and gives precise repair
/// locations for malformed keymaps.
pub(all) enum StructuralKind {
  MissingRootContext
  DuplicateId
  EmptyId
  EmptyCommand
  InvalidIdentifier
  MissingParent
  ContextCycle
  NegativeRank
  InvalidPlatform
  InvalidReservedMarker
  InvalidShortcut
  EmptyDescription
} derive(Eq, @debug.Debug)

///|
pub(all) struct StructuralIssue {
  kind : StructuralKind
  code : String
  message : String
  id : String
  line : Int
  severity : Severity
} derive(Eq, @debug.Debug)

///|
pub(all) struct ValidationReport {
  keymap_name : String
  issues : Array[StructuralIssue]
  error_count : Int
  warning_count : Int
  valid : Bool
} derive(Eq, @debug.Debug)

///|
fn structural_name(kind : StructuralKind) -> String {
  match kind {
    MissingRootContext => "missing-root-context"
    DuplicateId => "duplicate-id"
    EmptyId => "empty-id"
    EmptyCommand => "empty-command"
    InvalidIdentifier => "invalid-identifier"
    MissingParent => "missing-parent"
    ContextCycle => "context-cycle"
    NegativeRank => "negative-rank"
    InvalidPlatform => "invalid-platform"
    InvalidReservedMarker => "invalid-reserved-marker"
    InvalidShortcut => "invalid-shortcut"
    EmptyDescription => "empty-description"
  }
}

///|
fn structural_issue(
  kind : StructuralKind,
  message : String,
  id : String,
  line : Int,
  severity : Severity,
) -> StructuralIssue {
  { kind, code: "SV-" + structural_name(kind), message, id, line, severity, }
}

///|
fn valid_identifier(value : String) -> Bool {
  if value.length() == 0 {
    return false
  }
  for character in value {
    let n = character.to_int()
    let valid = (n >= 65 && n <= 90) ||
      (n >= 97 && n <= 122) ||
      (n >= 48 && n <= 57) ||
      character == '_' ||
      character == '-' ||
      character == '.'
    if !valid {
      return false
    }
  }
  true
}

///|
fn valid_platform(value : String) -> Bool {
  let clean = lower_ascii(trim_ascii(value))
  if clean.length() == 0 {
    return false
  }
  for part in platform_parts(clean) {
    if !valid_identifier(part) {
      return false
    }
  }
  true
}

///|
fn context_has_cycle(keymap : Keymap, start : String) -> Bool {
  let visited : Array[String] = []
  let mut current = start
  let mut steps = 0
  while current.length() > 0 && steps <= keymap.contexts.length() {
    if array_contains(visited, current) {
      return true
    }
    visited.push(current)
    match context_by_name(keymap, current) {
      Some(context) => current = context.parent
      None => current = ""
    }
    steps += 1
  }
  steps > keymap.contexts.length()
}

///|
/// Inspect all declarations without applying conflict policy.
pub fn validate_keymap(keymap : Keymap) -> ValidationReport {
  let issues : Array[StructuralIssue] = []
  if !context_exists(keymap, "global") {
    issues.push(
      structural_issue(
        MissingRootContext,
        "global context is required",
        "global",
        0,
        Error,
      ),
    )
  }
  for i, left in keymap.bindings {
    if left.id.length() == 0 {
      issues.push(
        structural_issue(
          EmptyId,
          "binding id cannot be empty",
          left.id,
          left.line,
          Error,
        ),
      )
    } else if !valid_identifier(left.id) {
      issues.push(
        structural_issue(
          InvalidIdentifier,
          "binding id contains unsupported characters",
          left.id,
          left.line,
          Error,
        ),
      )
    }
    if left.command.length() == 0 {
      issues.push(
        structural_issue(
          EmptyCommand,
          "command cannot be empty",
          left.id,
          left.line,
          Error,
        ),
      )
    } else if !valid_identifier(left.command) {
      issues.push(
        structural_issue(
          InvalidIdentifier,
          "command contains unsupported characters",
          left.id,
          left.line,
          Warning,
        ),
      )
    }
    if !context_exists(keymap, left.context) {
      issues.push(
        structural_issue(
          MissingParent,
          "binding context is not declared",
          left.id,
          left.line,
          Error,
        ),
      )
    }
    if left.priority < 0 {
      issues.push(
        structural_issue(
          NegativeRank,
          "binding priority should not be negative",
          left.id,
          left.line,
          Warning,
        ),
      )
    }
    if !valid_platform(left.platform) {
      issues.push(
        structural_issue(
          InvalidPlatform,
          "platform is empty or malformed",
          left.id,
          left.line,
          Error,
        ),
      )
    }
    if left.keys.canonical.length() == 0 {
      issues.push(
        structural_issue(
          InvalidShortcut,
          "shortcut did not produce a canonical form",
          left.id,
          left.line,
          Error,
        ),
      )
    }
    if left.description.length() == 0 {
      issues.push(
        structural_issue(
          EmptyDescription,
          "description is recommended for reviewability",
          left.id,
          left.line,
          Warning,
        ),
      )
    }
    let mut j = i + 1
    while j < keymap.bindings.length() {
      let right = keymap.bindings[j]
      if left.id == right.id {
        issues.push(
          structural_issue(
            DuplicateId,
            "binding id occurs more than once",
            left.id,
            right.line,
            Error,
          ),
        )
      }
      j += 1
    }
  }
  for context in keymap.contexts {
    if context.parent.length() > 0 && !context_exists(keymap, context.parent) {
      issues.push(
        structural_issue(
          MissingParent,
          "context parent is not declared",
          context.name,
          0,
          Error,
        ),
      )
    }
    if context.rank < 0 {
      issues.push(
        structural_issue(
          NegativeRank,
          "context rank should not be negative",
          context.name,
          0,
          Warning,
        ),
      )
    }
    if context_has_cycle(keymap, context.name) {
      issues.push(
        structural_issue(
          ContextCycle,
          "context parent chain contains a cycle",
          context.name,
          0,
          Error,
        ),
      )
    }
  }
  for marker in keymap.reserved {
    let (platform, shortcut) = split_once(marker, ":")
    if !valid_platform(platform) || parse_keys(shortcut) is Err(_) {
      issues.push(
        structural_issue(
          InvalidReservedMarker,
          "reserved marker must be platform:shortcut",
          marker,
          0,
          Error,
        ),
      )
    }
  }
  let errors = issues.filter(item => item.severity == Error).length()
  let warnings = issues.filter(item => item.severity == Warning).length()
  {
    keymap_name: keymap.name,
    issues,
    error_count: errors,
    warning_count: warnings,
    valid: errors == 0,
  }
}

///|
pub fn structural_issue_to_json(issue : StructuralIssue) -> String {
  "{\"code\":" +
  json_string(issue.code) +
  ",\"kind\":" +
  json_string(structural_name(issue.kind)) +
  ",\"severity\":" +
  json_string(issue.severity.name()) +
  ",\"message\":" +
  json_string(issue.message) +
  ",\"id\":" +
  json_string(issue.id) +
  ",\"line\":" +
  issue.line.to_string() +
  "}"
}

///|
pub fn validation_to_json(report : ValidationReport) -> String {
  let rows : Array[String] = []
  for issue in report.issues {
    rows.push(structural_issue_to_json(issue))
  }
  "{\"keymap\":" +
  json_string(report.keymap_name) +
  ",\"valid\":" +
  (if report.valid { "true" } else { "false" }) +
  ",\"errors\":" +
  report.error_count.to_string() +
  ",\"warnings\":" +
  report.warning_count.to_string() +
  ",\"issues\":[" +
  rows.join(",") +
  "]}"
}

///|
pub fn validation_to_markdown(report : ValidationReport) -> String {
  let lines : Array[String] = [
    "## Structural validation",
    "",
    "Result: **" + (if report.valid { "VALID" } else { "INVALID" }) + "**",
    "",
    "| Severity | Code | Identifier | Message |",
    "| --- | --- | --- | --- |",
  ]
  for issue in report.issues {
    lines.push(
      "| " +
      issue.severity.name() +
      " | `" +
      issue.code +
      "` | `" +
      issue.id +
      "` | " +
      issue.message +
      " |",
    )
  }
  if report.issues.length() == 0 {
    lines.push("| - | - | - | no structural issues |")
  }
  lines.join("\n")
}
