///|
/// Replacement chord suggestions are deterministic and never mutate a keymap.
fn candidate_keys() -> Array[String] {
  [
    "Ctrl+Shift+P", "Ctrl+Shift+O", "Ctrl+Shift+L", "Ctrl+Shift+K", "Ctrl+Alt+P",
    "Ctrl+Alt+O", "Ctrl+Alt+L", "Ctrl+Alt+K", "Alt+Shift+P", "Alt+Shift+O", "Alt+Shift+L",
    "Alt+Shift+K", "Ctrl+Shift+1", "Ctrl+Shift+2", "Ctrl+Shift+3", "Ctrl+Shift+4",
    "Ctrl+Alt+1", "Ctrl+Alt+2", "Ctrl+Alt+3", "Ctrl+Alt+4",
  ]
}

///|
fn candidate_is_free(
  keymap : Keymap,
  binding : Binding,
  candidate : KeySequence,
) -> Bool {
  for other in keymap.bindings {
    if other.id != binding.id &&
      other.enabled &&
      other.keys.canonical == candidate.canonical &&
      contexts_overlap(keymap, binding.context, other.context) &&
      platforms_overlap(binding.platform, other.platform) {
      return false
    }
  }
  for marker in keymap.reserved {
    let (_, reserved_key) = split_once(marker, ":")
    if reserved_key == candidate.canonical {
      return false
    }
  }
  true
}

///|
/// Suggest up to `limit` free alternatives for one binding.
pub fn suggest_for(
  keymap : Keymap,
  binding : Binding,
  limit? : Int = 3,
) -> Array[Suggestion] {
  let result : Array[Suggestion] = []
  let maximum = if limit < 0 { 0 } else { limit }
  for raw in candidate_keys() {
    if result.length() >= maximum {
      break
    }
    match parse_keys(raw) {
      Err(_) => ()
      Ok(candidate) =>
        if candidate.canonical != binding.keys.canonical &&
          candidate_is_free(keymap, binding, candidate) {
          let confidence = if candidate.modifier_count ==
            binding.keys.modifier_count {
            90
          } else {
            70
          }
          result.push({
            binding_id: binding.id,
            command: binding.command,
            current: binding.keys.canonical,
            replacement: candidate.canonical,
            reason: "free in the same context and platform scope",
            confidence,
          })
        }
    }
  }
  result
}

///|
/// Suggest alternatives for every binding carrying a finding.
pub fn suggest_all(
  keymap : Keymap,
  analysis : Analysis,
  limit? : Int = 3,
) -> Array[Suggestion] {
  let result : Array[Suggestion] = []
  let seen : Array[String] = []
  for finding in analysis.findings {
    if finding.kind == ExactConflict ||
      finding.kind == PrefixConflict ||
      finding.kind == ReservedShortcut ||
      finding.kind == AccessibilityRisk {
      for binding in keymap.bindings {
        if binding.id == finding.primary_id && !array_contains(seen, binding.id) {
          seen.push(binding.id)
          for suggestion in suggest_for(keymap, binding, limit~) {
            result.push(suggestion)
          }
        }
      }
    }
  }
  result
}

///|
/// Render suggestions as a simple Markdown checklist.
pub fn suggestions_to_markdown(suggestions : Array[Suggestion]) -> String {
  let lines : Array[String] = ["## Suggested replacements", ""]
  if suggestions.length() == 0 {
    lines.push("No replacement is needed.")
  }
  for suggestion in suggestions {
    lines.push(
      "- `" +
      suggestion.binding_id +
      "` (`" +
      suggestion.current +
      "`) → `" +
      suggestion.replacement +
      "` — " +
      suggestion.reason +
      " (confidence " +
      suggestion.confidence.to_string() +
      ")",
    )
  }
  lines.join("\n")
}
