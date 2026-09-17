///|
priv enum Expr {
  Literal(Bool)
  Key(String)
  Not(Expr)
  And(Expr, Expr)
  Or(Expr, Expr)
} derive(Eq, @debug.Debug)

///|
fn identifier_char(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') ||
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '_' ||
  ch == '.' ||
  ch == '-' ||
  ch == ':'
}

///|
fn tokens(text : String) -> Result[Array[String], String] {
  if text.length() > 1024 {
    return Err("when expression exceeds 1024 code units")
  }
  let chars = text.to_array()
  let result : Array[String] = []
  let mut i = 0
  while i < chars.length() {
    let ch = chars[i]
    if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
      i += 1
      continue
    }
    if ch == '!' || ch == '(' || ch == ')' {
      result.push(ch.to_string())
      i += 1
    } else if ch == '&' || ch == '|' {
      if i + 1 >= chars.length() || chars[i + 1] != ch {
        return Err("expected && or ||")
      }
      result.push(if ch == '&' { "&&" } else { "||" })
      i += 2
    } else if identifier_char(ch) {
      let word = StringBuilder()
      while i < chars.length() && identifier_char(chars[i]) {
        word.write_char(chars[i])
        i += 1
      }
      result.push(word.to_string())
    } else {
      return Err(
        "unsupported when operator; supported: boolean keys, !, &&, ||, parentheses",
      )
    }
    if result.length() > 128 {
      return Err("when expression exceeds 128 tokens")
    }
  }
  Ok(result)
}

///|
fn parse_atom(
  items : Array[String],
  start : Int,
  depth : Int,
) -> Result[(Expr, Int), String] {
  if depth > 32 {
    return Err("when nesting exceeds 32")
  }
  if start >= items.length() {
    return Err("incomplete when expression")
  }
  match items[start] {
    "!" =>
      match parse_atom(items, start + 1, depth + 1) {
        Ok((expr, next)) => Ok((Not(expr), next))
        Err(error) => Err(error)
      }
    "(" =>
      match parse_or(items, start + 1, depth + 1) {
        Ok((expr, next)) =>
          if next < items.length() && items[next] == ")" {
            Ok((expr, next + 1))
          } else {
            Err("unclosed when parenthesis")
          }
        Err(error) => Err(error)
      }
    ")" | "&&" | "||" => Err("expected a boolean context key")
    "true" => Ok((Literal(true), start + 1))
    "false" => Ok((Literal(false), start + 1))
    key => Ok((Key(key), start + 1))
  }
}

///|
fn parse_and(
  items : Array[String],
  start : Int,
  depth : Int,
) -> Result[(Expr, Int), String] {
  let (first, position) = match parse_atom(items, start, depth) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mut expr = first
  let mut next = position
  while next < items.length() && items[next] == "&&" {
    match parse_atom(items, next + 1, depth) {
      Ok((right, end)) => {
        expr = And(expr, right)
        next = end
      }
      Err(error) => return Err(error)
    }
  }
  Ok((expr, next))
}

///|
fn parse_or(
  items : Array[String],
  start : Int,
  depth : Int,
) -> Result[(Expr, Int), String] {
  let (first, position) = match parse_and(items, start, depth) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mut expr = first
  let mut next = position
  while next < items.length() && items[next] == "||" {
    match parse_and(items, next + 1, depth) {
      Ok((right, end)) => {
        expr = Or(expr, right)
        next = end
      }
      Err(error) => return Err(error)
    }
  }
  Ok((expr, next))
}

///|
fn compile_when(text : String) -> Result[Expr, String] {
  let items = match tokens(text) {
    Ok(items) => items
    Err(error) => return Err(error)
  }
  if items.is_empty() {
    return Ok(Literal(true))
  }
  match parse_or(items, 0, 0) {
    Ok((expr, end)) =>
      if end == items.length() {
        Ok(expr)
      } else {
        Err("unexpected when token")
      }
    Err(error) => Err(error)
  }
}

///|
fn eval(expr : Expr, values : Map[String, Bool]) -> Result[Bool, String] {
  match expr {
    Literal(value) => Ok(value)
    Key(key) =>
      match values.get(key) {
        Some(value) => Ok(value)
        None => Err("missing boolean context: " + key)
      }
    Not(inner) => eval(inner, values).map(x => !x)
    And(left, right) =>
      match (eval(left, values), eval(right, values)) {
        (Ok(false), _) | (_, Ok(false)) => Ok(false)
        (Ok(true), Ok(true)) => Ok(true)
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    Or(left, right) =>
      match (eval(left, values), eval(right, values)) {
        (Ok(true), _) | (_, Ok(true)) => Ok(true)
        (Ok(false), Ok(false)) => Ok(false)
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
/// Evaluate only the documented boolean subset; missing data is not assumed false.
pub fn evaluate_when(
  text : String,
  context : Map[String, Bool],
) -> Result[Bool, String] {
  match compile_when(text) {
    Ok(expr) => eval(expr, context)
    Err(error) => Err(error)
  }
}
