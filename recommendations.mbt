///|
/// Human-oriented recommendations derived from machine findings.
pub(all) enum Effort {
  Small
  Medium
  Large
} derive(Eq, @debug.Debug)

///|
pub(all) struct Recommendation {
  code : String
  title : String
  priority : Int
  severity : Severity
  effort : Effort
  affected_ids : Array[String]
  rationale : String
  action : String
} derive(Eq, @debug.Debug)

///|
fn effort_name(effort : Effort) -> String {
  match effort {
    Small => "small"
    Medium => "medium"
    Large => "large"
  }
}

///|
fn recommendation_for_finding(finding : Finding) -> Recommendation {
  let effort = match finding.kind {
    ExactConflict => Medium
    PrefixConflict => Medium
    ShadowedBinding => Small
    DuplicateCommand => Small
    ReservedShortcut => Small
    AccessibilityRisk => Medium
    InvalidKey => Small
    InvalidContext => Small
    InvalidRecord => Small
    DisabledBinding => Medium
    PlatformOverlap => Medium
  }
  let priority = match finding.severity {
    Error => 1
    Warning => 2
    Info => 3
  }
  let title = match finding.kind {
    ExactConflict => "Resolve exact shortcut conflict"
    PrefixConflict => "Disambiguate chord prefix"
    ShadowedBinding => "Document or remove shadowed binding"
    DuplicateCommand => "Explain duplicate command mapping"
    ReservedShortcut => "Move reserved shortcut"
    AccessibilityRisk => "Improve keyboard accessibility"
    InvalidKey => "Correct invalid key spelling"
    InvalidContext => "Declare the missing context"
    InvalidRecord => "Repair malformed keymap record"
    DisabledBinding => "Review disabled binding"
    PlatformOverlap => "Separate platform fallback"
  }
  {
    code: "REC-" + finding.code,
    title,
    priority,
    severity: finding.severity,
    effort,
    affected_ids: if finding.secondary_id.length() == 0 {
      [finding.primary_id]
    } else {
      [finding.primary_id, finding.secondary_id]
    },
    rationale: finding.message,
    action: finding.suggestion,
  }
}

///|
fn recommendation_compare(left : Recommendation, right : Recommendation) -> Int {
  if left.priority < right.priority {
    -1
  } else if left.priority > right.priority {
    1
  } else if left.code < right.code {
    -1
  } else if left.code > right.code {
    1
  } else {
    0
  }
}

///|
/// Build one actionable item per finding, deduplicated by finding code and ids.
pub fn recommendations(analysis : Analysis) -> Array[Recommendation] {
  let result : Array[Recommendation] = []
  let signatures : Array[String] = []
  for finding in analysis.findings {
    let signature = finding.code +
      ":" +
      finding.primary_id +
      ":" +
      finding.secondary_id
    if !array_contains(signatures, signature) {
      signatures.push(signature)
      result.push(recommendation_for_finding(finding))
    }
  }
  result.sort_by(recommendation_compare)
  result
}

///|
/// Add maintainability advice even when no conflict exists.
pub fn health_recommendations(
  keymap : Keymap,
  analysis : Analysis,
) -> Array[Recommendation] {
  let result = recommendations(analysis)
  let metrics = keymap_metrics(keymap)
  if metrics.documented_count < metrics.binding_count {
    result.push({
      code: "REC-DOCS",
      title: "Document every user-visible binding",
      priority: 3,
      severity: Warning,
      effort: Medium,
      affected_ids: [],
      rationale: "undocumented shortcuts are difficult to discover and review",
      action: "add a concise description= value to each binding",
    })
  }
  if metrics.duplicate_command_count > 0 {
    result.push({
      code: "REC-COMMANDS",
      title: "Explain duplicate command mappings",
      priority: 3,
      severity: Info,
      effort: Small,
      affected_ids: [],
      rationale: "duplicate mappings can be intentional across contexts but should be explicit",
      action: "add context-specific notes or consolidate the command",
    })
  }
  if metrics.modifierless_count > 0 {
    result.push({
      code: "REC-ACCESS",
      title: "Review modifierless shortcuts",
      priority: 2,
      severity: Warning,
      effort: Medium,
      affected_ids: [],
      rationale: "single keys are easy to trigger while typing",
      action: "provide a modifier chord and a documented alternative",
    })
  }
  result.sort_by(recommendation_compare)
  result
}

///|
pub fn recommendations_to_json(items : Array[Recommendation]) -> String {
  let rows : Array[String] = []
  for item in items {
    let ids : Array[String] = []
    for id in item.affected_ids {
      ids.push(json_string(id))
    }
    rows.push(
      "{\"code\":" +
      json_string(item.code) +
      ",\"title\":" +
      json_string(item.title) +
      ",\"priority\":" +
      item.priority.to_string() +
      ",\"severity\":" +
      json_string(item.severity.name()) +
      ",\"effort\":" +
      json_string(effort_name(item.effort)) +
      ",\"ids\":[" +
      ids.join(",") +
      "],\"rationale\":" +
      json_string(item.rationale) +
      ",\"action\":" +
      json_string(item.action) +
      "}",
    )
  }
  "[" + rows.join(",") + "]"
}

///|
pub fn recommendations_to_markdown(items : Array[Recommendation]) -> String {
  let lines : Array[String] = [
    "## Recommended actions", "", "| Priority | Code | Finding | Effort | Action |",
    "| ---: | --- | --- | --- | --- |",
  ]
  if items.length() == 0 {
    lines.push("| - | - | No action required | - | - |")
  }
  for item in items {
    lines.push(
      "| " +
      item.priority.to_string() +
      " | `" +
      item.code +
      "` | " +
      item.title +
      " | " +
      effort_name(item.effort) +
      " | " +
      item.action +
      " |",
    )
  }
  lines.join("\n")
}
