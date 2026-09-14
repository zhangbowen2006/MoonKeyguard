///|
/// Parser for the intentionally small, review-friendly keymap DSL.
///
/// Records are line oriented so a diff shows exactly which binding changed.
/// Example: `bind save command=editor.save keys=Ctrl+S context=editor`.
fn parse_attributes(
  tokens : Array[String],
  start : Int,
) -> Array[(String, String)] {
  let attributes : Array[(String, String)] = []
  for i in start..<tokens.length() {
    let token = tokens[i]
    let (key, value) = split_once(token, "=")
    if value.length() > 0 {
      attributes.push((lower_ascii(trim_ascii(key)), unquote(value)))
    }
  }
  attributes
}

///|
fn attr(
  attributes : Array[(String, String)],
  name : String,
  default : String,
) -> String {
  for pair in attributes {
    let key = pair.0
    let value = pair.1
    if key == name {
      return value
    }
  }
  default
}

///|
fn parse_header(tokens : Array[String], keymap : Keymap) -> Keymap {
  let attrs = parse_attributes(tokens, 1)
  let name = attr(attrs, "name", keymap.name)
  let version = attr(attrs, "version", keymap.version)
  { ..keymap, name, version }
}

///|
fn add_context(
  keymap : Keymap,
  tokens : Array[String],
  line : Int,
  diagnostics : Array[ParseDiagnostic],
) -> Keymap {
  let attrs = parse_attributes(tokens, 1)
  let positional = if tokens.length() > 1 && tokens[1].find("=") is None {
    tokens[1]
  } else {
    ""
  }
  let name = attr(attrs, "name", positional)
  if name.length() == 0 {
    diagnostics.push({
      line,
      code: "missing-context-name",
      message: "context requires name=...",
      source: "context",
    })
    return keymap
  }
  let parent = attr(
    attrs,
    "parent",
    if name == "global" {
      ""
    } else {
      "global"
    },
  )
  let rank = int_value(attr(attrs, "rank", "0"), 0)
  let description = attr(attrs, "description", "")
  match context_index(keymap, name) {
    Some(index) => {
      let old = keymap.contexts[index]
      if name == "global" && old.parent.length() == 0 {
        let contexts = keymap.contexts.copy()
        contexts[index] = { name, parent, rank, description }
        { ..keymap, contexts, }
      } else {
        diagnostics.push({
          line,
          code: "duplicate-context",
          message: "context '" + name + "' already exists",
          source: name,
        })
        keymap
      }
    }
    None =>
      {
        ..keymap,
        contexts: keymap.contexts + [{ name, parent, rank, description }],
      }
  }
}

///|
fn add_reserved(
  keymap : Keymap,
  tokens : Array[String],
  line : Int,
  diagnostics : Array[ParseDiagnostic],
) -> Keymap {
  if tokens.length() < 2 {
    diagnostics.push({
      line,
      code: "missing-reserved-key",
      message: "reserve requires a shortcut",
      source: "reserve",
    })
    return keymap
  }
  let raw = tokens[1]
  match parse_keys(raw) {
    Ok(sequence) => {
      let platform = attr(parse_attributes(tokens, 2), "platform", "all")
      let marker = platform + ":" + sequence.canonical
      if !array_contains(keymap.reserved, marker) {
        { ..keymap, reserved: keymap.reserved + [marker] }
      } else {
        keymap
      }
    }
    Err(message) => {
      diagnostics.push({
        line,
        code: "invalid-reserved-key",
        message,
        source: raw,
      })
      keymap
    }
  }
}

///|
fn add_binding(
  keymap : Keymap,
  tokens : Array[String],
  line : Int,
  source : String,
  diagnostics : Array[ParseDiagnostic],
) -> Keymap {
  if tokens.length() < 2 {
    diagnostics.push({
      line,
      code: "missing-binding-id",
      message: "bind requires an id",
      source,
    })
    return keymap
  }
  let id = tokens[1]
  let attrs = parse_attributes(tokens, 2)
  let command = attr(attrs, "command", "")
  let raw_keys = attr(
    attrs,
    "keys",
    if tokens.length() > 2 && tokens[2].find("=") is None {
      tokens[2]
    } else {
      ""
    },
  )
  let context = attr(attrs, "context", "global")
  let platform = attr(attrs, "platform", "all")
  let priority = int_value(attr(attrs, "priority", "0"), 0)
  let enabled = bool_value(attr(attrs, "enabled", "true"), true)
  let description = attr(attrs, "description", "")
  if command.length() == 0 {
    diagnostics.push({
      line,
      code: "missing-command",
      message: "binding requires command=...",
      source: id,
    })
  }
  match parse_keys(raw_keys) {
    Ok(keys) => {
      let binding = Binding::new(
        id,
        command,
        keys,
        context~,
        platform~,
        source~,
        line~,
        priority~,
        enabled~,
        description~,
      )
      { ..keymap, bindings: keymap.bindings + [binding] }
    }
    Err(message) => {
      diagnostics.push({
        line,
        code: "invalid-keys",
        message: message + " (raw='" + raw_keys + "')",
        source: id,
      })
      keymap
    }
  }
}

///|
fn strip_comment(line : String) -> String {
  match line.find("#") {
    Some(index) => line[:index].to_owned()
    None => line
  }
}

///|
/// Parse a complete keymap document.
pub fn parse_keymap(source : String, name? : String = "keymap") -> ParseResult {
  let diagnostics : Array[ParseDiagnostic] = []
  let mut keymap = Keymap::empty(name~)
  let lines = source.split("\n")
  let mut line_number = 0
  for original in lines {
    line_number += 1
    let clean = trim_ascii(strip_comment(original.to_owned()))
    if clean.length() == 0 {
      continue
    }
    let tokens = words(clean)
    if tokens.length() == 0 {
      continue
    }
    match lower_ascii(tokens[0]) {
      "keymap" => keymap = parse_header(tokens, keymap)
      "context" =>
        keymap = add_context(keymap, tokens, line_number, diagnostics)
      "reserve" =>
        keymap = add_reserved(keymap, tokens, line_number, diagnostics)
      "bind" =>
        keymap = add_binding(keymap, tokens, line_number, name, diagnostics)
      "version" =>
        if tokens.length() > 1 {
          keymap = { ..keymap, version: tokens[1] }
        }
      other =>
        diagnostics.push({
          line: line_number,
          code: "unknown-directive",
          message: "unknown directive '" + other + "'",
          source: other,
        })
    }
  }
  { keymap, diagnostics, ok: diagnostics.length() == 0 }
}

///|
/// Create a minimal valid keymap without writing a DSL document.
pub fn keymap_from_bindings(name : String, bindings : Array[Binding]) -> Keymap {
  { ..Keymap::empty(name~), bindings, }
}
