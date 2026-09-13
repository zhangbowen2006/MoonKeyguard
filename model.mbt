///|
/// A severity attached to an analysis finding.
pub(all) enum Severity {
  Info
  Warning
  Error
} derive(Eq, @debug.Debug)

///|
/// The family of rule that produced a finding.
pub(all) enum IssueKind {
  ExactConflict
  PrefixConflict
  ShadowedBinding
  DuplicateCommand
  ReservedShortcut
  AccessibilityRisk
  InvalidKey
  InvalidContext
  InvalidRecord
  DisabledBinding
  PlatformOverlap
} derive(Eq, @debug.Debug)

///|
/// A normalized keyboard sequence. The textual form is stable and suitable for
/// reports, while `steps` keeps each chord available to library consumers.
pub(all) struct KeySequence {
  raw : String
  steps : Array[String]
  canonical : String
  has_modifier : Bool
  modifier_count : Int
  key_count : Int
} derive(Eq, @debug.Debug)

///|
/// A single shortcut declaration from a keymap file.
pub(all) struct Binding {
  id : String
  command : String
  keys : KeySequence
  context : String
  platform : String
  source : String
  line : Int
  priority : Int
  enabled : Bool
  description : String
} derive(Eq, @debug.Debug)

///|
/// A context declaration. Contexts form a small inheritance tree used when
/// deciding whether one binding shadows another.
pub(all) struct Context {
  name : String
  parent : String
  rank : Int
  description : String
} derive(Eq, @debug.Debug)

///|
/// A finding emitted by the analyzer.
pub(all) struct Finding {
  code : String
  kind : IssueKind
  severity : Severity
  message : String
  primary_id : String
  secondary_id : String
  shortcut : String
  context : String
  source : String
  line : Int
  suggestion : String
} derive(Eq, @debug.Debug)

///|
/// All data needed to analyze one keymap.
pub(all) struct Keymap {
  name : String
  version : String
  bindings : Array[Binding]
  contexts : Array[Context]
  reserved : Array[String]
} derive(Eq, @debug.Debug)

///|
/// A complete deterministic analysis result.
pub(all) struct Analysis {
  keymap_name : String
  findings : Array[Finding]
  checked_bindings : Int
  enabled_bindings : Int
  error_count : Int
  warning_count : Int
  info_count : Int
  score : Int
  fingerprint : String
} derive(Eq, @debug.Debug)

///|
/// A candidate replacement suggested for a problematic binding.
pub(all) struct Suggestion {
  binding_id : String
  command : String
  current : String
  replacement : String
  reason : String
  confidence : Int
} derive(Eq, @debug.Debug)

///|
/// Parse diagnostics are kept separate from policy findings.
pub(all) struct ParseDiagnostic {
  line : Int
  code : String
  message : String
  source : String
} derive(Eq, @debug.Debug)

///|
/// Result returned by the line-oriented keymap parser.
pub(all) struct ParseResult {
  keymap : Keymap
  diagnostics : Array[ParseDiagnostic]
  ok : Bool
} derive(Eq, @debug.Debug)

///|
/// Construct an empty keymap.
pub fn Keymap::empty(name? : String = "keymap") -> Keymap {
  {
    name,
    version: "1",
    bindings: [],
    contexts: [
      { name: "global", parent: "", rank: 0, description: "all windows" },
    ],
    reserved: [],
  }
}

///|
/// Construct a normalized sequence value.
pub fn KeySequence::new(
  raw : String,
  steps : Array[String],
  canonical : String,
  has_modifier : Bool,
  modifier_count : Int,
) -> KeySequence {
  {
    raw,
    steps,
    canonical,
    has_modifier,
    modifier_count,
    key_count: steps.length(),
  }
}

///|
/// Construct a binding with sensible defaults for programmatic callers.
pub fn Binding::new(
  id : String,
  command : String,
  keys : KeySequence,
  context? : String = "global",
  platform? : String = "all",
  source? : String = "api",
  line? : Int = 0,
  priority? : Int = 0,
  enabled? : Bool = true,
  description? : String = "",
) -> Binding {
  {
    id,
    command,
    keys,
    context,
    platform,
    source,
    line,
    priority,
    enabled,
    description,
  }
}

///|
/// Return the stable identifier used in reports.
pub fn Binding::label(self : Binding) -> String {
  if self.source.length() == 0 {
    self.id
  } else {
    self.source + ":" + self.line.to_string() + ":" + self.id
  }
}

///|
/// Return the issue severity as a machine-readable string.
pub fn Severity::name(self : Severity) -> String {
  match self {
    Info => "info"
    Warning => "warning"
    Error => "error"
  }
}

///|
/// Return the issue kind as a stable kebab-case code.
pub fn IssueKind::name(self : IssueKind) -> String {
  match self {
    ExactConflict => "exact-conflict"
    PrefixConflict => "prefix-conflict"
    ShadowedBinding => "shadowed-binding"
    DuplicateCommand => "duplicate-command"
    ReservedShortcut => "reserved-shortcut"
    AccessibilityRisk => "accessibility-risk"
    InvalidKey => "invalid-key"
    InvalidContext => "invalid-context"
    InvalidRecord => "invalid-record"
    DisabledBinding => "disabled-binding"
    PlatformOverlap => "platform-overlap"
  }
}

///|
/// Convert a finding into a compact human-readable line.
pub fn Finding::to_line(self : Finding) -> String {
  let location = if self.source.length() == 0 {
    ""
  } else {
    self.source + ":" + self.line.to_string()
  }
  let pair = if self.secondary_id.length() == 0 {
    self.primary_id
  } else {
    self.primary_id + " vs " + self.secondary_id
  }
  self.severity.name().to_upper() +
  " " +
  self.code +
  " " +
  location +
  " " +
  pair +
  ": " +
  self.message
}

///|
/// True when the analysis has no error-level findings.
pub fn Analysis::ok(self : Analysis) -> Bool {
  self.error_count == 0
}

///|
/// Count findings of a particular kind.
pub fn Analysis::count_kind(self : Analysis, kind : IssueKind) -> Int {
  let mut total = 0
  for finding in self.findings {
    if finding.kind == kind {
      total += 1
    }
  }
  total
}

///|
/// Return a compact summary intended for CI logs.
pub fn Analysis::summary(self : Analysis) -> String {
  self.keymap_name +
  ": " +
  self.checked_bindings.to_string() +
  " bindings, " +
  self.error_count.to_string() +
  " errors, " +
  self.warning_count.to_string() +
  " warnings, score " +
  self.score.to_string() +
  "/100, fingerprint " +
  self.fingerprint
}
