///|
/// Append-only audit timeline for tracking keymap evolution in CI.
pub(all) enum TimelineEventKind {
  Imported
  Analyzed
  Approved
  Rejected
  Migrated
} derive(Eq, @debug.Debug)

///|
pub(all) struct TimelineEvent {
  sequence : Int
  label : String
  actor : String
  kind : TimelineEventKind
  fingerprint : String
  errors : Int
  warnings : Int
  score : Int
  note : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct AuditTimeline {
  project : String
  events : Array[TimelineEvent]
  baseline : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct TimelineDelta {
  previous : TimelineEvent?
  current : TimelineEvent
  score_delta : Int
  errors_delta : Int
  warnings_delta : Int
  regressed : Bool
} derive(Eq, @debug.Debug)

///|
pub fn AuditTimeline::new(
  project : String,
  baseline? : String = "",
) -> AuditTimeline {
  { project, events: [], baseline, }
}

///|
fn event_kind_name(kind : TimelineEventKind) -> String {
  match kind {
    Imported => "imported"
    Analyzed => "analyzed"
    Approved => "approved"
    Rejected => "rejected"
    Migrated => "migrated"
  }
}

///|
/// Append an event with a monotonically increasing sequence number.
pub fn timeline_append(
  timeline : AuditTimeline,
  label : String,
  actor : String,
  kind : TimelineEventKind,
  analysis : Analysis,
  note? : String = "",
) -> AuditTimeline {
  let sequence = timeline.events.length() + 1
  let event = {
    sequence,
    label,
    actor,
    kind,
    fingerprint: analysis.fingerprint,
    errors: analysis.error_count,
    warnings: analysis.warning_count,
    score: analysis.score,
    note,
  }
  { ..timeline, events: timeline.events + [event], }
}

///|
/// Record an analysis event and choose Approved/Rejected from the result.
pub fn timeline_record_gate(
  timeline : AuditTimeline,
  label : String,
  actor : String,
  analysis : Analysis,
  note? : String = "",
) -> AuditTimeline {
  let kind = if analysis.ok() { Approved } else { Rejected }
  timeline_append(timeline, label, actor, kind, analysis, note~)
}

///|
pub fn timeline_latest(timeline : AuditTimeline) -> TimelineEvent? {
  if timeline.events.length() == 0 {
    None
  } else {
    Some(timeline.events[timeline.events.length() - 1])
  }
}

///|
/// Compare the latest event with the immediately preceding one.
pub fn timeline_delta(timeline : AuditTimeline) -> TimelineDelta? {
  if timeline.events.length() == 0 {
    None
  } else {
    let current = timeline.events[timeline.events.length() - 1]
    let previous = if timeline.events.length() > 1 {
      Some(timeline.events[timeline.events.length() - 2])
    } else {
      None
    }
    let score_delta = match previous {
      Some(item) => current.score - item.score
      None => 0
    }
    let errors_delta = match previous {
      Some(item) => current.errors - item.errors
      None => current.errors
    }
    let warnings_delta = match previous {
      Some(item) => current.warnings - item.warnings
      None => current.warnings
    }
    Some({
      previous,
      current,
      score_delta,
      errors_delta,
      warnings_delta,
      regressed: errors_delta > 0 || score_delta < 0,
    })
  }
}

///|
/// Return all regressions after the baseline event.
pub fn timeline_regressions(timeline : AuditTimeline) -> Array[TimelineDelta] {
  let result : Array[TimelineDelta] = []
  for i in 1..<timeline.events.length() {
    let previous = timeline.events[i - 1]
    let current = timeline.events[i]
    let score_delta = current.score - previous.score
    let errors_delta = current.errors - previous.errors
    let warnings_delta = current.warnings - previous.warnings
    if errors_delta > 0 || score_delta < 0 {
      result.push({
        previous: Some(previous),
        current,
        score_delta,
        errors_delta,
        warnings_delta,
        regressed: true,
      })
    }
  }
  result
}

///|
pub fn timeline_to_json(timeline : AuditTimeline) -> String {
  let events : Array[String] = []
  for event in timeline.events {
    events.push(
      "{\"sequence\":" +
      event.sequence.to_string() +
      ",\"label\":" +
      json_string(event.label) +
      ",\"actor\":" +
      json_string(event.actor) +
      ",\"kind\":" +
      json_string(event_kind_name(event.kind)) +
      ",\"fingerprint\":" +
      json_string(event.fingerprint) +
      ",\"errors\":" +
      event.errors.to_string() +
      ",\"warnings\":" +
      event.warnings.to_string() +
      ",\"score\":" +
      event.score.to_string() +
      ",\"note\":" +
      json_string(event.note) +
      "}",
    )
  }
  "{\"project\":" +
  json_string(timeline.project) +
  ",\"baseline\":" +
  json_string(timeline.baseline) +
  ",\"events\":[" +
  events.join(",") +
  "]}"
}

///|
pub fn timeline_to_markdown(timeline : AuditTimeline) -> String {
  let lines : Array[String] = [
    "## Audit timeline: " + timeline.project,
    "",
    "| # | Label | Actor | Kind | Errors | Warnings | Score | Fingerprint |",
    "| ---: | --- | --- | --- | ---: | ---: | ---: | --- |",
  ]
  for event in timeline.events {
    lines.push(
      "| " +
      event.sequence.to_string() +
      " | " +
      event.label +
      " | " +
      event.actor +
      " | " +
      event_kind_name(event.kind) +
      " | " +
      event.errors.to_string() +
      " | " +
      event.warnings.to_string() +
      " | " +
      event.score.to_string() +
      " | `" +
      event.fingerprint +
      "` |",
    )
  }
  lines.push("")
  lines.push(
    "Regressions detected: " +
    timeline_regressions(timeline).length().to_string(),
  )
  lines.join("\n")
}

///|
/// Return a stable summary useful for release notes.
pub fn timeline_summary(timeline : AuditTimeline) -> String {
  let latest = match timeline_latest(timeline) {
    Some(event) =>
      "latest=" +
      event.label +
      " score=" +
      event.score.to_string() +
      " errors=" +
      event.errors.to_string()
    None => "latest=none"
  }
  timeline.project +
  ": events=" +
  timeline.events.length().to_string() +
  ", " +
  latest +
  ", regressions=" +
  timeline_regressions(timeline).length().to_string()
}
