///|
/// Conflict analysis engine.
fn push_if_some(findings : Array[Finding], item : Finding?) -> Unit {
  match item {
    Some(finding) => findings.push(finding)
    None => ()
  }
}

///|
fn enabled_bindings(keymap : Keymap) -> Array[Binding] {
  keymap.bindings.filter(binding => binding.enabled)
}

///|
fn exact_or_prefix(left : Binding, right : Binding) -> IssueKind? {
  if left.keys.canonical == right.keys.canonical {
    Some(ExactConflict)
  } else if key_prefix(left.keys, right.keys) ||
    key_prefix(right.keys, left.keys) {
    Some(PrefixConflict)
  } else {
    None
  }
}

///|
fn analyze_pair(
  keymap : Keymap,
  left : Binding,
  right : Binding,
  findings : Array[Finding],
) -> Unit {
  if !contexts_overlap(keymap, left.context, right.context) ||
    !platforms_overlap(left.platform, right.platform) {
    return
  }
  match exact_or_prefix(left, right) {
    None => ()
    Some(ExactConflict) => {
      if left.command == right.command {
        findings.push(
          pair_finding(
            "MK103",
            DuplicateCommand,
            Info,
            "the same command is bound more than once in overlapping scopes",
            left,
            right,
            "keep both only when the duplicate is intentional and documented",
          ),
        )
      } else {
        findings.push(
          pair_finding(
            "MK001",
            ExactConflict,
            Error,
            "two different commands claim the same shortcut in overlapping scopes",
            left,
            right,
            "change one chord, context, platform, or priority",
          ),
        )
      }
      let winner = more_specific(keymap, left, right)
      let loser = if winner.id == left.id { right } else { left }
      if winner.command != loser.command && winner.priority != loser.priority {
        findings.push(
          pair_finding(
            "MK002",
            ShadowedBinding,
            Warning,
            "a lower-priority binding is shadowed by a more specific binding",
            loser,
            winner,
            "make the priority explicit or choose a non-overlapping chord",
          ),
        )
      }
      if left.platform != right.platform &&
        (
          lower_ascii(left.platform) == "all" ||
          lower_ascii(right.platform) == "all"
        ) {
        findings.push(
          pair_finding(
            "MK003",
            PlatformOverlap,
            Warning,
            "an all-platform binding overlaps a platform-specific binding",
            left,
            right,
            "split the all-platform declaration or document the intended fallback",
          ),
        )
      }
    }
    Some(PrefixConflict) =>
      findings.push(
        pair_finding(
          "MK004",
          PrefixConflict,
          Warning,
          "a shorter chord is a prefix of another chord and can delay or swallow input",
          left,
          right,
          "use a timeout-aware dispatcher or choose chords with distinct prefixes",
        ),
      )
    Some(_) => ()
  }
}

///|
fn count_severity(findings : Array[Finding], severity : Severity) -> Int {
  let mut count = 0
  for item in findings {
    if item.severity == severity {
      count += 1
    }
  }
  count
}

///|
fn score_findings(findings : Array[Finding]) -> Int {
  let mut score = 100
  for finding in findings {
    match finding.severity {
      Error => score -= 18
      Warning => score -= 6
      Info => score -= 1
    }
  }
  if score < 0 {
    0
  } else {
    score
  }
}

///|
/// Analyze declarations using all built-in rules.
pub fn analyze(keymap : Keymap) -> Analysis {
  let findings : Array[Finding] = []
  let active = enabled_bindings(keymap)
  for binding in keymap.bindings {
    push_if_some(findings, invalid_context_finding(keymap, binding))
    push_if_some(findings, accessibility_finding(binding))
    push_if_some(findings, reserved_finding(keymap, binding))
    push_if_some(findings, disabled_finding(binding))
  }
  for i in 0..<keymap.bindings.length() {
    let mut j = i + 1
    while j < keymap.bindings.length() {
      let left = keymap.bindings[i]
      let right = keymap.bindings[j]
      if left.id == right.id {
        findings.push(duplicate_id_finding(left, right))
      }
      if left.enabled && right.enabled {
        analyze_pair(keymap, left, right, findings)
      }
      j += 1
    }
  }
  let errors = count_severity(findings, Error)
  let warnings = count_severity(findings, Warning)
  let infos = count_severity(findings, Info)
  {
    keymap_name: keymap.name,
    findings,
    checked_bindings: keymap.bindings.length(),
    enabled_bindings: active.length(),
    error_count: errors,
    warning_count: warnings,
    info_count: infos,
    score: score_findings(findings),
    fingerprint: keymap_fingerprint(keymap),
  }
}

///|
/// Parse and analyze in one call for CLI and integrations.
pub fn audit(
  source : String,
  name? : String = "keymap",
) -> (ParseResult, Analysis) {
  let parsed = parse_keymap(source, name~)
  (parsed, analyze(parsed.keymap))
}
