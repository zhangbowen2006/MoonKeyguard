///|
/// Semantic keymap diffing for review and migration planning.
pub(all) enum ChangeKind {
  Added
  Removed
  Modified
  Unchanged
} derive(Eq, @debug.Debug)

///|
pub(all) struct BindingChange {
  kind : ChangeKind
  id : String
  before : Binding?
  after : Binding?
  summary : String
  risk : Severity
} derive(Eq, @debug.Debug)

///|
pub(all) struct KeymapDiff {
  from_name : String
  to_name : String
  changes : Array[BindingChange]
  added : Int
  removed : Int
  modified : Int
  unchanged : Int
  context_added : Int
  context_removed : Int
  reserved_added : Int
  reserved_removed : Int
} derive(Eq, @debug.Debug)

///|
fn binding_equal(left : Binding, right : Binding) -> Bool {
  left.command == right.command &&
  left.keys.canonical == right.keys.canonical &&
  left.context == right.context &&
  lower_ascii(left.platform) == lower_ascii(right.platform) &&
  left.priority == right.priority &&
  left.enabled == right.enabled &&
  left.description == right.description
}

///|
fn binding_change(
  id : String,
  before : Binding,
  after : Binding,
) -> BindingChange {
  let key_changed = before.keys.canonical != after.keys.canonical
  let context_changed = before.context != after.context
  let command_changed = before.command != after.command
  let summary = if command_changed {
    "command " + before.command + " → " + after.command
  } else if key_changed {
    "shortcut " + before.keys.canonical + " → " + after.keys.canonical
  } else if context_changed {
    "context " + before.context + " → " + after.context
  } else {
    "metadata or priority changed"
  }
  let risk = if command_changed || key_changed { Error } else { Warning }
  {
    kind: Modified,
    id,
    before: Some(before),
    after: Some(after),
    summary,
    risk,
  }
}

///|
fn context_names(keymap : Keymap) -> Array[String] {
  keymap.contexts.map(context => context.name)
}

///|
fn marker_count_difference(
  before : Array[String],
  after : Array[String],
) -> (Int, Int) {
  let mut added = 0
  let mut removed = 0
  for marker in after {
    if !array_contains(before, marker) {
      added += 1
    }
  }
  for marker in before {
    if !array_contains(after, marker) {
      removed += 1
    }
  }
  (added, removed)
}

///|
/// Compare declarations by id and retain unchanged entries for auditability.
pub fn diff_keymaps(before : Keymap, after : Keymap) -> KeymapDiff {
  let changes : Array[BindingChange] = []
  let mut added = 0
  let mut removed = 0
  let mut modified = 0
  let mut unchanged = 0
  for old_binding in before.bindings {
    match find_binding(after, old_binding.id) {
      None => {
        removed += 1
        changes.push({
          kind: Removed,
          id: old_binding.id,
          before: Some(old_binding),
          after: None,
          summary: "binding removed",
          risk: Warning,
        })
      }
      Some(new_binding) =>
        if binding_equal(old_binding, new_binding) {
          unchanged += 1
          changes.push({
            kind: Unchanged,
            id: old_binding.id,
            before: Some(old_binding),
            after: Some(new_binding),
            summary: "unchanged",
            risk: Info,
          })
        } else {
          modified += 1
          changes.push(binding_change(old_binding.id, old_binding, new_binding))
        }
    }
  }
  for new_binding in after.bindings {
    if find_binding(before, new_binding.id) is None {
      added += 1
      changes.push({
        kind: Added,
        id: new_binding.id,
        before: None,
        after: Some(new_binding),
        summary: "binding added",
        risk: Info,
      })
    }
  }
  let (context_added, context_removed) = marker_count_difference(
    context_names(before),
    context_names(after),
  )
  let (reserved_added, reserved_removed) = marker_count_difference(
    before.reserved,
    after.reserved,
  )
  {
    from_name: before.name,
    to_name: after.name,
    changes,
    added,
    removed,
    modified,
    unchanged,
    context_added,
    context_removed,
    reserved_added,
    reserved_removed,
  }
}

///|
fn change_kind_name(kind : ChangeKind) -> String {
  match kind {
    Added => "added"
    Removed => "removed"
    Modified => "modified"
    Unchanged => "unchanged"
  }
}

///|
/// Return only changes that may alter runtime behavior.
pub fn behavioral_changes(diff : KeymapDiff) -> Array[BindingChange] {
  diff.changes.filter(change => change.kind != Unchanged && change.risk != Info)
}

///|
pub fn keymap_diff_to_json(diff : KeymapDiff) -> String {
  let rows : Array[String] = []
  for change in diff.changes {
    rows.push(
      "{\"kind\":" +
      json_string(change_kind_name(change.kind)) +
      ",\"id\":" +
      json_string(change.id) +
      ",\"summary\":" +
      json_string(change.summary) +
      ",\"risk\":" +
      json_string(change.risk.name()) +
      "}",
    )
  }
  "{\"from\":" +
  json_string(diff.from_name) +
  ",\"to\":" +
  json_string(diff.to_name) +
  ",\"added\":" +
  diff.added.to_string() +
  ",\"removed\":" +
  diff.removed.to_string() +
  ",\"modified\":" +
  diff.modified.to_string() +
  ",\"unchanged\":" +
  diff.unchanged.to_string() +
  ",\"changes\":[" +
  rows.join(",") +
  "]}"
}

///|
/// Render a migration plan that can be copied into a release checklist.
pub fn migration_plan(diff : KeymapDiff) -> String {
  let lines : Array[String] = [
    "# Keymap migration plan",
    "",
    "From: `" + diff.from_name + "` → `" + diff.to_name + "`",
    "",
    "- added bindings: " + diff.added.to_string(),
    "- removed bindings: " + diff.removed.to_string(),
    "- modified bindings: " + diff.modified.to_string(),
    "- changed contexts: +" +
    diff.context_added.to_string() +
    " / -" +
    diff.context_removed.to_string(),
    "- changed reserved shortcuts: +" +
    diff.reserved_added.to_string() +
    " / -" +
    diff.reserved_removed.to_string(),
    "",
    "## Actions",
  ]
  for change in behavioral_changes(diff) {
    let marker = match change.kind {
      Added => "[ ] add"
      Removed => "[ ] remove"
      Modified => "[ ] review"
      Unchanged => "[x] keep"
    }
    lines.push("- " + marker + " `" + change.id + "`: " + change.summary)
  }
  if behavioral_changes(diff).length() == 0 {
    lines.push("- [x] no behavioral migration required")
  }
  lines.join("\n")
}

///|
/// Apply a diff's additions and modifications to a base keymap.
pub fn apply_keymap_diff(
  base : Keymap,
  target : Keymap,
  include_removed? : Bool = false,
) -> Keymap {
  let diff = diff_keymaps(base, target)
  let result = base.bindings.copy()
  for change in diff.changes {
    match change.kind {
      Added =>
        match change.after {
          Some(binding) => result.push(binding)
          None => ()
        }
      Modified =>
        match change.after {
          Some(binding) =>
            match binding_index({ ..base, bindings: result, }, binding.id) {
              Some(index) => result[index] = binding
              None => result.push(binding)
            }
          None => ()
        }
      Removed => if include_removed { () }
      Unchanged => ()
    }
  }
  { ..target, bindings: result, }
}
