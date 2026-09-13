///|
/// Small text helpers kept dependency-free so the core also works on wasm.
fn is_space_code(c : UInt16) -> Bool {
  let n = c.to_int()
  n == 32 || n == 9 || n == 10 || n == 13
}

///|
fn ascii_lower_char(c : Char) -> Char {
  c.to_ascii_lowercase()
}

///|
fn lower_ascii(value : String) -> String {
  let out = StringBuilder()
  for c in value {
    out.write_char(ascii_lower_char(c))
  }
  out.to_string()
}

///|
fn trim_ascii(value : String) -> String {
  let mut start = 0
  let mut finish = value.length()
  while start < finish && is_space_code(value.unsafe_get(start)) {
    start += 1
  }
  while finish > start && is_space_code(value.unsafe_get(finish - 1)) {
    finish -= 1
  }
  value[start:finish].to_owned()
}

///|
fn words(value : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = StringBuilder()
  for c in value {
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      let part = trim_ascii(current.to_string())
      if part.length() > 0 {
        result.push(part)
      }
      current = StringBuilder()
    } else {
      current.write_char(c)
    }
  }
  let tail = trim_ascii(current.to_string())
  if tail.length() > 0 {
    result.push(tail)
  }
  result
}

///|
fn split_once(value : String, delimiter : String) -> (String, String) {
  match value.find(delimiter) {
    Some(index) =>
      (value[:index].to_owned(), value[index + delimiter.length():].to_owned())
    None => (value, "")
  }
}

///|
fn unquote(value : String) -> String {
  let clean = trim_ascii(value)
  if clean.length() >= 2 &&
    (
      (clean[0] == '"' && clean[clean.length() - 1] == '"') ||
      (clean[0] == '\'' && clean[clean.length() - 1] == '\'')
    ) {
    clean[1:clean.length() - 1].to_owned()
  } else {
    clean
  }
}

///|
fn bool_value(value : String, default : Bool) -> Bool {
  match lower_ascii(unquote(value)) {
    "true" => true
    "yes" => true
    "on" => true
    "1" => true
    "false" => false
    "no" => false
    "off" => false
    "0" => false
    _ => default
  }
}

///|
fn int_value(value : String, default : Int) -> Int {
  @string.parse_int(unquote(value)) catch {
    _ => default
  }
}

///|
fn array_contains(items : Array[String], wanted : String) -> Bool {
  for item in items {
    if item == wanted {
      break true
    }
  } nobreak {
    false
  }
}

///|
fn string_or_default(value : String, default : String) -> String {
  if value.length() == 0 {
    default
  } else {
    value
  }
}
