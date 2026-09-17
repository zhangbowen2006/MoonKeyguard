///|
priv struct Rule {
  id : String
  command : String
  keys : @kit.KeySequence
  condition : Result[Expr, String]
  when_text : String
  unsupported : String
}

///|
fn get_field(value : Json, name : String) -> Json? {
  if value is Object(fields) {
    fields.get(name)
  } else {
    None
  }
}

///|
fn string_field(
  value : Json,
  name : String,
  fallback? : String,
) -> Result[String, String] {
  match get_field(value, name) {
    Some(String(text)) => Ok(text)
    None =>
      match fallback {
        Some(text) => Ok(text)
        None => Err("missing " + name)
      }
    _ => Err(name + " must be a string")
  }
}

///|
fn decode(text : String, label : String) -> Result[Json, String] {
  if text.length() > 1048576 {
    return Err(label + ": document exceeds 1 Mi code units")
  }
  let result = @json5.parse(text) catch {
    error => return Err(label + ": invalid JSON/JSONC: " + error.to_string())
  }
  Ok(result)
}

///|
fn lower(text : String) -> String {
  let out = StringBuilder()
  for ch in text.iter() {
    out.write_char(
      if ch >= 'A' && ch <= 'Z' {
        Int::unsafe_to_char(ch.to_int() + 32)
      } else {
        ch
      },
    )
  }
  out.to_string()
}

///|
fn accepted_key(key : String) -> Bool {
  if key.length() == 1 {
    let ch = key.unsafe_get(0).to_int()
    return (ch >= 97 && ch <= 122) || (ch >= 48 && ch <= 57)
  }
  if [
      "enter", "escape", "esc", "tab", "space", "backspace", "delete", "insert",
      "home", "end", "up", "down", "left", "right", "pageup", "pagedown",
    ].contains(key) {
    return true
  }
  if key.has_prefix("f") {
    let number = @string.parse_int(key[1:]) catch { _ => return false }
    return number >= 1 && number <= 24 && key == "f" + number.to_string()
  }
  false
}

///|
/// Avoid pretending punctuation/scan codes are layout independent.
fn host_keys(raw : String) -> Result[@kit.KeySequence, String] {
  let text = lower(raw).replace(old="\t", new=" ")
  let chords = text.split(" ").filter(x => !x.is_empty()).to_array()
  if chords.is_empty() || chords.length() > 4 {
    return Err("expected 1..4 space-separated chords")
  }
  for chord in chords {
    let pieces = chord.split("+").map(x => x.to_owned()).to_array()
    if pieces.is_empty() || !accepted_key(pieces[pieces.length() - 1]) {
      return Err("unsupported key/layout notation: " + raw)
    }
    for i in 0..<(pieces.length() - 1) {
      if !["ctrl", "shift", "alt", "cmd", "meta", "win"].contains(pieces[i]) {
        return Err("unsupported modifier: " + pieces[i])
      }
    }
  }
  @kit.parse_keys(text)
}

///|
fn import_rules(
  source : Json,
  layer : String,
  platform : String,
) -> Result[Array[Rule], String] {
  let entries = match source {
    Array(rows) => rows
    _ => return Err(layer + ": expected keybinding array")
  }
  if entries.length() > 2000 {
    return Err(layer + ": more than 2000 rules")
  }
  let result : Array[Rule] = []
  for index, entry in entries {
    let id = layer + "[" + (index + 1).to_string() + "]"
    if !(entry is Object(_)) {
      return Err(id + ": expected object")
    }
    let command = match string_field(entry, "command") {
      Ok(value) => value
      Err(error) => return Err(id + ": " + error)
    }
    let base = match string_field(entry, "key") {
      Ok(value) => value
      Err(error) => return Err(id + ": " + error)
    }
    let slot = if platform == "windows" { "win" } else { platform }
    let raw_keys = if layer == "extension" {
      match string_field(entry, slot, fallback=base) {
        Ok(value) => value
        Err(error) => return Err(id + ": " + error)
      }
    } else {
      base
    }
    let keys = match host_keys(raw_keys) {
      Ok(value) => value
      Err(error) => return Err(id + ": " + error)
    }
    let when_text = match string_field(entry, "when", fallback="") {
      Ok(value) => value
      Err(error) => return Err(id + ": " + error)
    }
    let mut unsupported = ""
    // Such rules remain in their precedence position and cannot yield a false PASS.
    if command.has_prefix("-") {
      unsupported = "removal rules are not supported"
    }
    if command == "" {
      unsupported = "empty-command disabling rules are not supported"
    }
    if get_field(entry, "args") is Some(_) {
      unsupported = "command arguments are not covered by this contract"
    }
    if get_field(entry, "systemWide") is Some(_) {
      unsupported = "systemWide host behavior is not supported"
    }
    if entry is Object(fields) {
      for field, _ in fields {
        let allowed = ["key", "command", "when", "args", "systemWide"].contains(
            field,
          ) ||
          (layer == "extension" && ["win", "mac", "linux"].contains(field))
        if !allowed {
          unsupported = "unsupported rule field: " + field
        }
      }
    }
    result.push({
      id,
      command,
      keys,
      condition: compile_when(when_text),
      when_text,
      unsupported,
    })
  }
  Ok(result)
}
