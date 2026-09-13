///|
/// Keymap metrics used to track maintainability over time.
pub(all) struct KeymapMetrics {
  binding_count : Int
  enabled_count : Int
  context_count : Int
  platform_count : Int
  command_count : Int
  max_chord_length : Int
  average_chord_length : Int
  modifierless_count : Int
  documented_count : Int
  duplicate_command_count : Int
  density_score : Int
} derive(Eq, @debug.Debug)

///|
fn unique_strings(values : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for value in values {
    if !array_contains(result, value) {
      result.push(value)
    }
  }
  result
}

///|
/// Calculate counts without relying on hash maps, keeping the library small.
pub fn keymap_metrics(keymap : Keymap) -> KeymapMetrics {
  let commands : Array[String] = []
  let platforms : Array[String] = []
  let mut enabled = 0
  let mut max_length = 0
  let mut total_length = 0
  let mut modifierless = 0
  let mut documented = 0
  for binding in keymap.bindings {
    commands.push(binding.command)
    platforms.push(lower_ascii(binding.platform))
    if binding.enabled {
      enabled += 1
    }
    if binding.keys.steps.length() > max_length {
      max_length = binding.keys.steps.length()
    }
    total_length += binding.keys.steps.length()
    if !binding.keys.has_modifier {
      modifierless += 1
    }
    if binding.description.length() > 0 {
      documented += 1
    }
  }
  let unique_commands = unique_strings(commands)
  let duplicate_commands = keymap.bindings.length() - unique_commands.length()
  let average = if keymap.bindings.length() == 0 {
    0
  } else {
    total_length / keymap.bindings.length()
  }
  let density = if keymap.bindings.length() == 0 {
    0
  } else {
    enabled * 100 / keymap.bindings.length()
  }
  {
    binding_count: keymap.bindings.length(),
    enabled_count: enabled,
    context_count: keymap.contexts.length(),
    platform_count: unique_strings(platforms).length(),
    command_count: unique_commands.length(),
    max_chord_length: max_length,
    average_chord_length: average,
    modifierless_count: modifierless,
    documented_count: documented,
    duplicate_command_count: duplicate_commands,
    density_score: density,
  }
}

///|
pub fn metrics_to_json(metrics : KeymapMetrics) -> String {
  "{" +
  "\"bindings\":" +
  metrics.binding_count.to_string() +
  "," +
  "\"enabled\":" +
  metrics.enabled_count.to_string() +
  "," +
  "\"contexts\":" +
  metrics.context_count.to_string() +
  "," +
  "\"platforms\":" +
  metrics.platform_count.to_string() +
  "," +
  "\"commands\":" +
  metrics.command_count.to_string() +
  "," +
  "\"max_chord_length\":" +
  metrics.max_chord_length.to_string() +
  "," +
  "\"average_chord_length\":" +
  metrics.average_chord_length.to_string() +
  "," +
  "\"modifierless\":" +
  metrics.modifierless_count.to_string() +
  "," +
  "\"documented\":" +
  metrics.documented_count.to_string() +
  "," +
  "\"duplicate_commands\":" +
  metrics.duplicate_command_count.to_string() +
  "," +
  "\"density_score\":" +
  metrics.density_score.to_string() +
  "}"
}
