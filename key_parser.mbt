///|
/// Keyboard token parsing and canonicalization.
fn modifier_name(name : String) -> String {
  match lower_ascii(trim_ascii(name)) {
    "ctrl" => "Ctrl"
    "control" => "Ctrl"
    "cmd" => "Cmd"
    "command" => "Cmd"
    "meta" => "Cmd"
    "super" => "Cmd"
    "win" => "Cmd"
    "alt" => "Alt"
    "option" => "Alt"
    "shift" => "Shift"
    "ctrlorcmd" => "CtrlOrCmd"
    "primary" => "CtrlOrCmd"
    "hyper" => "Hyper"
    "fn" => "Fn"
    other => other
  }
}

///|
fn is_modifier(name : String) -> Bool {
  let canonical = modifier_name(name)
  canonical == "Ctrl" ||
  canonical == "Cmd" ||
  canonical == "Alt" ||
  canonical == "Shift" ||
  canonical == "CtrlOrCmd" ||
  canonical == "Hyper" ||
  canonical == "Fn"
}

///|
fn key_name(name : String) -> String {
  let clean = trim_ascii(name)
  let lower = lower_ascii(clean)
  match lower {
    "esc" => "Escape"
    "return" => "Enter"
    "del" => "Delete"
    "ins" => "Insert"
    "spacebar" => "Space"
    "spc" => "Space"
    "left" => "ArrowLeft"
    "right" => "ArrowRight"
    "up" => "ArrowUp"
    "down" => "ArrowDown"
    "pgup" => "PageUp"
    "pgdn" => "PageDown"
    "backspace" => "Backspace"
    "tab" => "Tab"
    "plus" => "Plus"
    "minus" => "Minus"
    "" => ""
    _ => if clean.length() == 1 { lower_ascii(clean) } else { clean }
  }
}

///|
fn order_modifier(name : String) -> Int {
  match name {
    "Ctrl" => 0
    "CtrlOrCmd" => 1
    "Cmd" => 2
    "Alt" => 3
    "Shift" => 4
    "Hyper" => 5
    "Fn" => 6
    _ => 20
  }
}

///|
fn contains_string(items : Array[String], wanted : String) -> Bool {
  for item in items {
    if item == wanted {
      break true
    }
  } nobreak {
    false
  }
}

///|
fn sort_modifiers(items : Array[String]) -> Array[String] {
  let out = items.copy()
  let mut i = 0
  while i < out.length() {
    let mut j = i + 1
    while j < out.length() {
      if order_modifier(out[j]) < order_modifier(out[i]) {
        let hold = out[i]
        out[i] = out[j]
        out[j] = hold
      }
      j += 1
    }
    i += 1
  }
  out
}

///|
fn parse_chord(raw : String) -> (String, Bool, Int, Bool) {
  let pieces = raw.split("+").map(x => x.to_owned()).to_array()
  let modifiers : Array[String] = []
  let mut key = ""
  let mut valid = true
  for piece in pieces {
    let clean = trim_ascii(piece)
    if clean.length() == 0 {
      valid = false
    } else if is_modifier(clean) {
      let normalized = modifier_name(clean)
      if !contains_string(modifiers, normalized) {
        modifiers.push(normalized)
      }
    } else if key.length() == 0 {
      key = key_name(clean)
    } else {
      valid = false
    }
  }
  if key.length() == 0 {
    valid = false
  }
  let ordered = sort_modifiers(modifiers)
  let text = if ordered.length() == 0 {
    key
  } else {
    ordered.join("+") + "+" + key
  }
  (text, ordered.length() > 0, ordered.length(), valid)
}

///|
/// Parse a sequence such as `Ctrl+K Ctrl+C` or `cmd+k,cmd+c`.
pub fn parse_keys(raw : String) -> Result[KeySequence, String] {
  let prepared = trim_ascii(raw).replace(old=",", new=" ")
  if prepared.length() == 0 {
    return Err("empty shortcut")
  }
  let source_steps = words(prepared)
  if source_steps.length() == 0 {
    return Err("empty shortcut")
  }
  let steps : Array[String] = []
  let mut has_modifier = false
  let mut modifier_count = 0
  for source in source_steps {
    let (normalized, modifier, count, valid) = parse_chord(source)
    if !valid {
      return Err("invalid chord '" + source + "'")
    }
    steps.push(normalized)
    has_modifier = has_modifier || modifier
    modifier_count += count
  }
  Ok(
    KeySequence::new(raw, steps, steps.join(" "), has_modifier, modifier_count),
  )
}

///|
/// Normalize a key sequence for comparisons. Invalid input returns an empty
/// string, which makes it safe to use in diagnostics without throwing.
pub fn canonical_keys(raw : String) -> String {
  let result = parse_keys(raw)
  match result {
    Ok(sequence) => sequence.canonical
    Err(_) => ""
  }
}

///|
/// True if the first sequence is a strict prefix of the second.
pub fn key_prefix(prefix : KeySequence, full : KeySequence) -> Bool {
  if prefix.steps.length() >= full.steps.length() {
    false
  } else {
    let mut same = true
    for i in 0..<prefix.steps.length() {
      if prefix.steps[i] != full.steps[i] {
        same = false
      }
    }
    same
  }
}

///|
/// Parse a modifier expression and expose a simple risk signal.
pub fn shortcut_has_modifier(sequence : KeySequence) -> Bool {
  sequence.has_modifier
}

///|
/// Return the final key without modifiers, useful for reserved-key policies.
pub fn shortcut_final_key(sequence : KeySequence) -> String {
  if sequence.steps.length() == 0 {
    ""
  } else {
    let final_chord = sequence.steps[sequence.steps.length() - 1]
    let parts = final_chord.split("+").map(x => x.to_owned()).to_array()
    parts[parts.length() - 1]
  }
}
