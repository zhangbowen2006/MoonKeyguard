///|
/// A deterministic context/platform probe matrix for shortcut reachability.
///
/// Conflict reports explain that two declarations overlap; this report answers
/// the complementary release question: for a concrete context and platform,
/// which binding actually wins, and which declarations are never selected?
pub(all) enum ReachabilityStatus {
  Reachable
  Shadowed
  Ambiguous
  Unavailable
  Disabled
} derive(Eq, @debug.Debug)

///|
pub(all) struct ReachabilityCell {
  binding_id : String
  context : String
  platform : String
  status : ReachabilityStatus
  selected_id : String
  message : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct ReachabilityReport {
  keymap_name : String
  contexts : Array[String]
  platforms : Array[String]
  cells : Array[ReachabilityCell]
  binding_count : Int
  reachable_count : Int
  shadowed_count : Int
  ambiguous_count : Int
  unavailable_count : Int
  disabled_count : Int
} derive(Eq, @debug.Debug)

///|
fn reachability_status_name(status : ReachabilityStatus) -> String {
  match status {
    Reachable => "reachable"
    Shadowed => "shadowed"
    Ambiguous => "ambiguous"
    Unavailable => "unavailable"
    Disabled => "disabled"
  }
}

///|
fn add_unique(values : Array[String], value : String) -> Unit {
  if value.length() > 0 && !array_contains(values, value) {
    values.push(value)
  }
}

///|
fn sorted_unique(values : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for value in values {
    add_unique(result, value)
  }
  result.sort()
  result
}

///|
fn sorted_platforms(values : Array[String]) -> Array[String] {
  let cleaned : Array[String] = []
  for value in values {
    add_unique(cleaned, lower_ascii(trim_ascii(value)))
  }
  sorted_unique(cleaned)
}

///|
fn reachability_cell(
  binding : Binding,
  context : String,
  platform : String,
  result : DispatchResult,
) -> ReachabilityCell {
  if !binding.enabled {
    return {
      binding_id: binding.id,
      context,
      platform,
      status: Disabled,
      selected_id: "",
      message: "binding is disabled and retained only for migration",
    }
  }
  let selected_id = if result.binding_ids.length() > 0 {
    result.binding_ids[0]
  } else {
    ""
  }
  let includes = array_contains(result.binding_ids, binding.id)
  if result.status == DispatchStatus::Ambiguous && includes {
    {
      binding_id: binding.id,
      context,
      platform,
      status: ReachabilityStatus::Ambiguous,
      selected_id,
      message: "binding ties with another equally specific declaration",
    }
  } else if result.status == DispatchStatus::Matched &&
    includes &&
    selected_id == binding.id {
    {
      binding_id: binding.id,
      context,
      platform,
      status: ReachabilityStatus::Reachable,
      selected_id,
      message: "binding is selected by the dispatcher",
    }
  } else if result.status == DispatchStatus::Matched && includes {
    {
      binding_id: binding.id,
      context,
      platform,
      status: ReachabilityStatus::Shadowed,
      selected_id,
      message: "another binding wins by priority or context specificity",
    }
  } else {
    {
      binding_id: binding.id,
      context,
      platform,
      status: ReachabilityStatus::Unavailable,
      selected_id,
      message: "binding is not active in this context and platform",
    }
  }
}

///|
/// Probe every declaration against the requested contexts and platforms.
///
/// Empty probe arrays mean all declared contexts and the `all` platform. The
/// resulting arrays are sorted and deduplicated so the report fingerprint can
/// be compared in CI without depending on caller order.
pub fn reachability_matrix(
  keymap : Keymap,
  contexts? : Array[String] = [],
  platforms? : Array[String] = [],
) -> ReachabilityReport {
  let context_values = if contexts.length() == 0 {
    let declared : Array[String] = []
    for context in keymap.contexts {
      add_unique(declared, context.name)
    }
    sorted_unique(declared)
  } else {
    sorted_unique(contexts)
  }
  let platform_values = if platforms.length() == 0 {
    ["all"]
  } else {
    sorted_platforms(platforms)
  }
  let cells : Array[ReachabilityCell] = []
  let mut reachable = 0
  let mut shadowed = 0
  let mut ambiguous = 0
  let mut unavailable = 0
  let mut disabled = 0
  for binding in keymap.bindings {
    for context in context_values {
      for platform in platform_values {
        let cell = reachability_cell(
          binding,
          context,
          platform,
          dispatch(keymap, binding.keys.raw, context~, platform~),
        )
        match cell.status {
          ReachabilityStatus::Reachable => reachable += 1
          ReachabilityStatus::Shadowed => shadowed += 1
          ReachabilityStatus::Ambiguous => ambiguous += 1
          ReachabilityStatus::Unavailable => unavailable += 1
          ReachabilityStatus::Disabled => disabled += 1
        }
        cells.push(cell)
      }
    }
  }
  {
    keymap_name: keymap.name,
    contexts: context_values,
    platforms: platform_values,
    cells,
    binding_count: keymap.bindings.length(),
    reachable_count: reachable,
    shadowed_count: shadowed,
    ambiguous_count: ambiguous,
    unavailable_count: unavailable,
    disabled_count: disabled,
  }
}

///|
pub fn ReachabilityReport::summary(self : ReachabilityReport) -> String {
  "reachability=" +
  self.keymap_name +
  " bindings=" +
  self.binding_count.to_string() +
  " reachable=" +
  self.reachable_count.to_string() +
  " shadowed=" +
  self.shadowed_count.to_string() +
  " ambiguous=" +
  self.ambiguous_count.to_string() +
  " unavailable=" +
  self.unavailable_count.to_string() +
  " disabled=" +
  self.disabled_count.to_string()
}

///|
pub fn reachability_to_markdown(report : ReachabilityReport) -> String {
  let lines : Array[String] = [
    "## Reachability matrix",
    "",
    report.summary(),
    "",
    "| Binding | Context | Platform | Status | Selected | Explanation |",
    "| --- | --- | --- | --- | --- | --- |",
  ]
  for cell in report.cells {
    lines.push(
      "| `" +
      cell.binding_id +
      "` | `" +
      cell.context +
      "` | `" +
      cell.platform +
      "` | " +
      reachability_status_name(cell.status) +
      " | `" +
      cell.selected_id +
      "` | " +
      cell.message +
      " |",
    )
  }
  lines.join("\n")
}

///|
pub fn reachability_to_json(report : ReachabilityReport) -> String {
  let rows : Array[String] = []
  for cell in report.cells {
    rows.push(
      "{\"binding\":" +
      json_string(cell.binding_id) +
      ",\"context\":" +
      json_string(cell.context) +
      ",\"platform\":" +
      json_string(cell.platform) +
      ",\"status\":" +
      json_string(reachability_status_name(cell.status)) +
      ",\"selected\":" +
      json_string(cell.selected_id) +
      ",\"message\":" +
      json_string(cell.message) +
      "}",
    )
  }
  "{\"keymap\":" +
  json_string(report.keymap_name) +
  ",\"contexts\":[" +
  report.contexts.map(item => json_string(item)).join(",") +
  "],\"platforms\":[" +
  report.platforms.map(item => json_string(item)).join(",") +
  "],\"bindings\":" +
  report.binding_count.to_string() +
  ",\"reachable\":" +
  report.reachable_count.to_string() +
  ",\"shadowed\":" +
  report.shadowed_count.to_string() +
  ",\"ambiguous\":" +
  report.ambiguous_count.to_string() +
  ",\"unavailable\":" +
  report.unavailable_count.to_string() +
  ",\"disabled\":" +
  report.disabled_count.to_string() +
  ",\"cells\":[" +
  rows.join(",") +
  "]}"
}
