///|
/// A small deterministic dispatcher simulation used to validate analyzer
/// assumptions without depending on a GUI or operating-system backend.
pub(all) enum DispatchStatus {
  Matched
  Prefix
  NoMatch
  Ambiguous
  Disabled
  Invalid
} derive(Eq, @debug.Debug)

///|
pub(all) struct DispatchResult {
  status : DispatchStatus
  input : String
  canonical : String
  command : String
  binding_ids : Array[String]
  context : String
  platform : String
  message : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct DispatchStep {
  input : String
  result : DispatchResult
  elapsed_ms : Int
} derive(Eq, @debug.Debug)

///|
pub(all) struct DispatchTrace {
  context : String
  platform : String
  steps : Array[DispatchStep]
  matched_count : Int
  prefix_count : Int
  no_match_count : Int
} derive(Eq, @debug.Debug)

///|
fn dispatch_result(
  status : DispatchStatus,
  input : String,
  canonical : String,
  command : String,
  ids : Array[String],
  context : String,
  platform : String,
  message : String,
) -> DispatchResult {
  {
    status,
    input,
    canonical,
    command,
    binding_ids: ids,
    context,
    platform,
    message,
  }
}

///|
fn dispatch_status_name(status : DispatchStatus) -> String {
  match status {
    Matched => "matched"
    Prefix => "prefix"
    NoMatch => "no-match"
    Ambiguous => "ambiguous"
    Disabled => "disabled"
    Invalid => "invalid"
  }
}

///|
fn matching_bindings(
  keymap : Keymap,
  sequence : KeySequence,
  context : String,
  platform : String,
) -> Array[Binding] {
  keymap.bindings.filter(binding => {
    binding.enabled &&
    binding.keys.canonical == sequence.canonical &&
    binding_active_in_context(keymap, binding.context, context) &&
    platforms_overlap(binding.platform, platform)
  })
}

///|
fn prefix_bindings(
  keymap : Keymap,
  sequence : KeySequence,
  context : String,
  platform : String,
) -> Array[Binding] {
  keymap.bindings.filter(binding => {
    binding.enabled &&
    key_prefix(sequence, binding.keys) &&
    binding_active_in_context(keymap, binding.context, context) &&
    platforms_overlap(binding.platform, platform)
  })
}

///|
fn sort_dispatch_candidates(
  keymap : Keymap,
  bindings : Array[Binding],
) -> Array[Binding] {
  let result = bindings.copy()
  result.sort_by((left, right) => {
    if left.priority > right.priority {
      -1
    } else if left.priority < right.priority {
      1
    } else {
      let left_rank = binding_context_rank(keymap, left)
      let right_rank = binding_context_rank(keymap, right)
      if left_rank > right_rank {
        -1
      } else if left_rank < right_rank {
        1
      } else if left.id < right.id {
        -1
      } else if left.id > right.id {
        1
      } else {
        0
      }
    }
  })
  result
}

///|
/// Resolve one complete or partial sequence.
pub fn dispatch(
  keymap : Keymap,
  raw : String,
  context? : String = "global",
  platform? : String = "all",
) -> DispatchResult {
  match parse_keys(raw) {
    Err(message) =>
      dispatch_result(Invalid, raw, "", "", [], context, platform, message)
    Ok(sequence) => {
      let exact = sort_dispatch_candidates(
        keymap,
        matching_bindings(keymap, sequence, context, platform),
      )
      if exact.length() > 0 {
        let ids : Array[String] = []
        for binding in exact {
          ids.push(binding.id)
        }
        let command = exact[0].command
        let status = if exact.length() > 1 &&
          exact[0].priority == exact[1].priority &&
          binding_context_rank(keymap, exact[0]) ==
          binding_context_rank(keymap, exact[1]) {
          DispatchStatus::Ambiguous
        } else {
          Matched
        }
        let message = if status == DispatchStatus::Ambiguous {
          "multiple equally specific bindings"
        } else {
          "selected highest-priority binding"
        }
        dispatch_result(
          status,
          raw,
          sequence.canonical,
          command,
          ids,
          context,
          platform,
          message,
        )
      } else if prefix_bindings(keymap, sequence, context, platform).length() >
        0 {
        dispatch_result(
          Prefix,
          raw,
          sequence.canonical,
          "",
          [],
          context,
          platform,
          "waiting for the next chord",
        )
      } else {
        let disabled = keymap.bindings
          .filter(binding => {
            !binding.enabled && binding.keys.canonical == sequence.canonical
          })
          .length() >
          0
        if disabled {
          dispatch_result(
            Disabled,
            raw,
            sequence.canonical,
            "",
            [],
            context,
            platform,
            "matching binding is disabled",
          )
        } else {
          dispatch_result(
            NoMatch,
            raw,
            sequence.canonical,
            "",
            [],
            context,
            platform,
            "no binding matches this context and platform",
          )
        }
      }
    }
  }
}

///|
/// Replay a sequence of user inputs and count outcomes.
pub fn replay(
  keymap : Keymap,
  inputs : Array[String],
  context? : String = "global",
  platform? : String = "all",
) -> DispatchTrace {
  let steps : Array[DispatchStep] = []
  let mut matched = 0
  let mut prefixes = 0
  let mut misses = 0
  let mut elapsed = 0
  for input in inputs {
    let result = dispatch(keymap, input, context~, platform~)
    match result.status {
      Matched => matched += 1
      Prefix => prefixes += 1
      _ => misses += 1
    }
    elapsed += 1
    steps.push({ input, result, elapsed_ms: elapsed })
  }
  {
    context,
    platform,
    steps,
    matched_count: matched,
    prefix_count: prefixes,
    no_match_count: misses,
  }
}

///|
pub fn dispatch_result_to_json(result : DispatchResult) -> String {
  let ids : Array[String] = []
  for id in result.binding_ids {
    ids.push(json_string(id))
  }
  "{\"status\":" +
  json_string(dispatch_status_name(result.status)) +
  ",\"input\":" +
  json_string(result.input) +
  ",\"canonical\":" +
  json_string(result.canonical) +
  ",\"command\":" +
  json_string(result.command) +
  ",\"bindings\":[" +
  ids.join(",") +
  "],\"message\":" +
  json_string(result.message) +
  "}"
}

///|
pub fn dispatch_trace_to_markdown(trace : DispatchTrace) -> String {
  let lines : Array[String] = [
    "## Dispatch replay",
    "",
    "Context: `" + trace.context + "`  Platform: `" + trace.platform + "`",
    "",
    "| Input | Status | Command | Message |",
    "| --- | --- | --- | --- |",
  ]
  for step in trace.steps {
    lines.push(
      "| `" +
      step.input +
      "` | " +
      dispatch_status_name(step.result.status) +
      " | `" +
      step.result.command +
      "` | " +
      step.result.message +
      " |",
    )
  }
  lines.push("")
  lines.push(
    "matched=" +
    trace.matched_count.to_string() +
    ", prefix=" +
    trace.prefix_count.to_string() +
    ", other=" +
    trace.no_match_count.to_string(),
  )
  lines.join("\n")
}

///|
/// Check that every command has at least one dispatchable binding.
pub fn unreachable_commands(
  keymap : Keymap,
  context : String,
  platform : String,
) -> Array[String] {
  let commands : Array[String] = []
  for binding in keymap.bindings {
    if !array_contains(commands, binding.command) {
      commands.push(binding.command)
    }
  }
  let missing_commands : Array[String] = []
  for command in commands {
    let bindings = select_bindings(
        keymap,
        command~,
        context~,
        platform~,
        enabled_only=true,
      ).bindings
    if bindings.length() == 0 {
      missing_commands.push(command)
    }
  }
  missing_commands
}
