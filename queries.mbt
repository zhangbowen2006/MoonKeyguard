///|
/// Query, projection, and deterministic serialization helpers.
pub(all) struct BindingQuery {
  binding : Binding
  context_distance : Int
  platform_match : Bool
  command_match : Bool
} derive(Eq, @debug.Debug)

///|
pub(all) struct KeymapSelection {
  name : String
  bindings : Array[Binding]
  contexts : Array[Context]
  query : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct MergeResult {
  keymap : Keymap
  conflicts : Array[String]
  adopted : Int
  skipped : Int
} derive(Eq, @debug.Debug)

///|
fn binding_index(keymap : Keymap, id : String) -> Int? {
  for i, binding in keymap.bindings {
    if binding.id == id {
      return Some(i)
    }
  }
  None
}

///|
/// Look up one binding by its stable id.
pub fn find_binding(keymap : Keymap, id : String) -> Binding? {
  match binding_index(keymap, id) {
    Some(index) => Some(keymap.bindings[index])
    None => None
  }
}

///|
/// Return all bindings belonging to a command, retaining declaration order.
pub fn find_command(keymap : Keymap, command : String) -> Array[Binding] {
  keymap.bindings.filter(binding => binding.command == command)
}

///|
fn context_distance(keymap : Keymap, ancestor : String, child : String) -> Int? {
  if ancestor == child {
    return Some(0)
  }
  let mut current = child
  let mut distance = 1
  while distance <= keymap.contexts.length() {
    match context_by_name(keymap, current) {
      Some(context) => {
        if context.parent.length() == 0 {
          return None
        }
        if context.parent == ancestor {
          return Some(distance)
        }
        current = context.parent
      }
      None => return None
    }
    distance += 1
  }
  None
}

///|
/// Resolve bindings active in a context. Parent declarations come first so a
/// caller can apply child-priority rules while streaming the result.
pub fn active_bindings(
  keymap : Keymap,
  context : String,
  platform : String,
) -> Array[BindingQuery] {
  let result : Array[BindingQuery] = []
  for binding in keymap.bindings {
    if binding.enabled &&
      binding_active_in_context(keymap, binding.context, context) &&
      platforms_overlap(binding.platform, platform) {
      let distance = match context_distance(keymap, binding.context, context) {
        Some(value) => value
        None => 0
      }
      result.push({
        binding,
        context_distance: distance,
        platform_match: platforms_overlap(binding.platform, platform),
        command_match: false,
      })
    }
  }
  result
}

///|
/// Query by optional command, context, platform, and enabled state.
pub fn select_bindings(
  keymap : Keymap,
  command? : String = "",
  context? : String = "",
  platform? : String = "all",
  enabled_only? : Bool = false,
) -> KeymapSelection {
  let result : Array[Binding] = []
  for binding in keymap.bindings {
    let command_ok = command.length() == 0 || binding.command == command
    let context_ok = context.length() == 0 ||
      binding_active_in_context(keymap, binding.context, context)
    let platform_ok = platforms_overlap(binding.platform, platform)
    let enabled_ok = !enabled_only || binding.enabled
    if command_ok && context_ok && platform_ok && enabled_ok {
      result.push(binding)
    }
  }
  {
    name: keymap.name,
    bindings: result,
    contexts: keymap.contexts,
    query: "command=" +
    command +
    ";context=" +
    context +
    ";platform=" +
    platform,
  }
}

///|
fn compare_bindings(left : Binding, right : Binding) -> Int {
  if left.id < right.id {
    -1
  } else if left.id > right.id {
    1
  } else {
    0
  }
}

///|
fn sorted_bindings(bindings : Array[Binding]) -> Array[Binding] {
  let output = bindings.copy()
  output.sort_by(compare_bindings)
  output
}

///|
/// Return a canonical copy with bindings and contexts sorted by name.
pub fn normalize_keymap(keymap : Keymap) -> Keymap {
  let bindings = sorted_bindings(keymap.bindings)
  let contexts = keymap.contexts.copy()
  contexts.sort_by((left, right) => {
    if left.name < right.name {
      -1
    } else if left.name > right.name {
      1
    } else {
      0
    }
  })
  let reserved = keymap.reserved.copy()
  reserved.sort()
  { ..keymap, bindings, contexts, reserved }
}

///|
fn binding_to_dsl(binding : Binding) -> String {
  let enabled = if binding.enabled { "true" } else { "false" }
  "bind " +
  binding.id +
  " command=" +
  binding.command +
  " keys=" +
  binding.keys.canonical +
  " context=" +
  binding.context +
  " platform=" +
  binding.platform +
  " priority=" +
  binding.priority.to_string() +
  " enabled=" +
  enabled +
  " description=" +
  binding.description
}

///|
/// Serialize a keymap back to a review-friendly DSL document.
pub fn keymap_to_dsl(keymap : Keymap) -> String {
  let normalized = normalize_keymap(keymap)
  let lines : Array[String] = [
    "keymap name=" + normalized.name + " version=" + normalized.version,
  ]
  for context in normalized.contexts {
    lines.push(
      "context " +
      context.name +
      " parent=" +
      context.parent +
      " rank=" +
      context.rank.to_string() +
      " description=" +
      context.description,
    )
  }
  for marker in normalized.reserved {
    let (platform, keys) = split_once(marker, ":")
    lines.push("reserve " + keys + " platform=" + platform)
  }
  for binding in normalized.bindings {
    lines.push(binding_to_dsl(binding))
  }
  lines.join("\n")
}

///|
/// Merge an overlay keymap. Existing ids are replaced only when `priority` is
/// at least as high; equal ids with a different command are reported.
pub fn merge_keymaps(base : Keymap, overlay : Keymap) -> MergeResult {
  let bindings = base.bindings.copy()
  let conflicts : Array[String] = []
  let mut adopted = 0
  let mut skipped = 0
  for incoming in overlay.bindings {
    match binding_index({ ..Keymap::empty(), bindings, }, incoming.id) {
      Some(index) => {
        let existing = bindings[index]
        if existing.command != incoming.command {
          conflicts.push(
            "id " +
            incoming.id +
            " changes command from " +
            existing.command +
            " to " +
            incoming.command,
          )
        }
        if incoming.priority >= existing.priority {
          bindings[index] = incoming
          adopted += 1
        } else {
          skipped += 1
        }
      }
      None => {
        bindings.push(incoming)
        adopted += 1
      }
    }
  }
  let merged_contexts = base.contexts.copy()
  for incoming in overlay.contexts {
    if !context_exists({ ..base, contexts: merged_contexts }, incoming.name) {
      merged_contexts.push(incoming)
    }
  }
  let merged_reserved = base.reserved.copy()
  for marker in overlay.reserved {
    if !array_contains(merged_reserved, marker) {
      merged_reserved.push(marker)
    }
  }
  {
    keymap: {
      ..base,
      version: overlay.version,
      bindings,
      contexts: merged_contexts,
      reserved: merged_reserved,
    },
    conflicts,
    adopted,
    skipped,
  }
}

///|
/// Return ids that are declared but cannot be reached in a context.
pub fn unreachable_bindings(
  keymap : Keymap,
  context : String,
  platform : String,
) -> Array[Binding] {
  keymap.bindings.filter(binding => {
    binding.enabled &&
    (
      !binding_active_in_context(keymap, binding.context, context) ||
      !platforms_overlap(binding.platform, platform)
    )
  })
}

///|
/// Return one binding per unique command, choosing the most specific one.
pub fn primary_commands(
  keymap : Keymap,
  context : String,
  platform : String,
) -> Array[Binding] {
  let result : Array[Binding] = []
  let commands : Array[String] = []
  for binding in keymap.bindings {
    if binding.enabled &&
      binding_active_in_context(keymap, binding.context, context) &&
      platforms_overlap(binding.platform, platform) {
      let mut command_index = -1
      for i, command in commands {
        if command == binding.command {
          command_index = i
        }
      }
      if command_index >= 0 {
        let index = command_index
        let winner = more_specific(keymap, result[index], binding)
        result[index] = winner
      } else {
        commands.push(binding.command)
        result.push(binding)
      }
    }
  }
  result
}

///|
/// Produce a compact selection report for API clients.
pub fn selection_to_text(selection : KeymapSelection) -> String {
  let lines : Array[String] = [
    "selection " + selection.query,
    "keymap=" +
    selection.name +
    " count=" +
    selection.bindings.length().to_string(),
  ]
  for binding in selection.bindings {
    lines.push(
      binding.id +
      " " +
      binding.keys.canonical +
      " " +
      binding.command +
      " [" +
      binding.context +
      "]",
    )
  }
  lines.join("\n")
}
