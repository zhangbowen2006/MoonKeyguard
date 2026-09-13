///|
/// Policy rules that do not depend on another binding.
fn finding(
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
fn pair_finding(
  code : String,
  kind : IssueKind,
  severity : Severity,
  message : String,
  left : Binding,
  right : Binding,
  suggestion : String,
) -> Finding {
  {
    code,
    kind,
    severity,
    message,
    primary_id: left.id,
    secondary_id: right.id,
    shortcut: left.keys.canonical,
    context: left.context,
    source: left.source,
    line: left.line,
    suggestion,
  }
}

///|
fn accessibility_finding(binding : Binding) -> Finding? {
  if !binding.keys.has_modifier && binding.keys.steps.length() == 1 {
    Some(
      finding(
        "MK201",
        AccessibilityRisk,
        Warning,
        "single-key binding has no modifier and may be triggered accidentally",
        binding,
        "prefer a documented modifier chord or mark the command as intentional",
      ),
    )
  } else if binding.keys.modifier_count > 3 {
    Some(
      finding(
        "MK202",
        AccessibilityRisk,
        Warning,
        "chord contains more than three modifiers and is difficult to operate",
        binding,
        "reduce the modifier count or provide a command-palette alternative",
      ),
    )
  } else {
    None
  }
}

///|
fn duplicate_id_finding(left : Binding, right : Binding) -> Finding {
  pair_finding(
    "MK101",
    InvalidRecord,
    Error,
    "binding ids must be unique within a keymap",
    left,
    right,
    "rename one id so review tools can address the binding unambiguously",
  )
}

///|
fn invalid_context_finding(keymap : Keymap, binding : Binding) -> Finding? {
  if context_exists(keymap, binding.context) {
    None
  } else {
    Some(
      finding(
        "MK102",
        InvalidContext,
        Error,
        "binding refers to an undeclared context",
        binding,
        "declare the context before using it, or use global",
      ),
    )
  }
}

///|
fn disabled_finding(binding : Binding) -> Finding? {
  if binding.enabled {
    None
  } else {
    Some(
      finding(
        "MK301",
        DisabledBinding,
        Info,
        "binding is disabled and will not be reachable at runtime",
        binding,
        "remove stale declarations or explain why the disabled entry is retained",
      ),
    )
  }
}

///|
fn reserved_finding(keymap : Keymap, binding : Binding) -> Finding? {
  if reserved_matches(keymap, binding) {
    Some(
      finding(
        "MK401",
        ReservedShortcut,
        Error,
        "shortcut is reserved by the operating system or product policy",
        binding,
        "choose a non-reserved chord or scope the binding to a safe platform",
      ),
    )
  } else {
    None
  }
}
