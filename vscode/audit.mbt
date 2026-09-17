///|
pub(all) struct AuditResult {
  json : String
  exit_code : Int
} derive(Eq, @debug.Debug)

///|
fn quote(text : String) -> String {
  Json::string(text).stringify()
}

///|
fn incomplete(error : String) -> AuditResult {
  {
    json: "{\"profile\":\"vscode-ordered-boolean-v1\",\"status\":\"inconclusive\",\"exit_code\":2,\"error\":" +
    quote(error) +
    "}",
    exit_code: 2,
  }
}

///|
fn prefix_matches(rule : Rule, input : @kit.KeySequence, count : Int) -> Bool {
  if rule.keys.steps.length() < count {
    return false
  }
  for i in 0..<count {
    if rule.keys.steps[i] != input.steps[i] {
      return false
    }
  }
  true
}

///|
/// Compare a supplied host snapshot with explicit intended dispatch contracts.
/// No claim about unlisted states, physical layouts or an actual running editor.
pub fn audit_sources(
  defaults : String,
  extension : String,
  overrides : String,
  scenarios : String,
  platform : String,
) -> AuditResult {
  if !["windows", "mac", "linux"].contains(platform) {
    return incomplete("platform must be windows, mac or linux")
  }
  let base_json = match decode(defaults, "defaults") {
    Ok(x) => x
    Err(e) => return incomplete(e)
  }
  let extension_json = match decode(extension, "extension") {
    Ok(x) => x
    Err(e) => return incomplete(e)
  }
  let user_json = match decode(overrides, "overrides") {
    Ok(x) => x
    Err(e) => return incomplete(e)
  }
  let probes_json = match decode(scenarios, "scenarios") {
    Ok(x) => x
    Err(e) => return incomplete(e)
  }
  let contributed = match get_field(extension_json, "contributes") {
    Some(value) =>
      match get_field(value, "keybindings") {
        Some(Array(rows)) => Json::array(rows)
        Some(Object(_)) as row => row.unwrap()
        _ =>
          return incomplete(
            "extension: contributes.keybindings must be an array or object",
          )
      }
    None => return incomplete("extension: missing contributes.keybindings")
  }
  let contributed = if contributed is Object(_) {
    Json::array([contributed])
  } else {
    contributed
  }
  let rules : Array[Rule] = []
  for
    (value, layer) in [
      (base_json, "defaults"),
      (contributed, "extension"),
      (user_json, "overrides"),
    ] {
    match import_rules(value, layer, platform) {
      Ok(items) =>
        for item in items {
          rules.push(item)
        }
      Err(error) => return incomplete(error)
    }
  }
  let probes = match probes_json {
    Array(items) => items
    _ => return incomplete("scenarios: expected array")
  }
  if probes.is_empty() || probes.length() > 128 {
    return incomplete("provide 1..128 explicit scenarios")
  }
  let rows : Array[String] = []
  let names : Map[String, Bool] = Map([])
  let mut failed = 0
  let mut unknown = 0
  for probe in probes {
    let name = match string_field(probe, "name") {
      Ok(x) => x
      Err(e) => return incomplete(e)
    }
    if name == "" || names.contains(name) {
      return incomplete("scenario names must be nonempty and unique")
    }
    names[name] = true
    let base_key = match string_field(probe, "key") {
      Ok(x) => x
      Err(e) => return incomplete(name + ": " + e)
    }
    let slot = if platform == "windows" { "win" } else { platform }
    let raw = match string_field(probe, slot, fallback=base_key) {
      Ok(x) => x
      Err(e) => return incomplete(name + ": " + e)
    }
    let input = match host_keys(raw) {
      Ok(x) => x
      Err(e) => return incomplete(name + ": " + e)
    }
    let expected = match get_field(probe, "expected_command") {
      Some(String(value)) if value != "" => Some(value)
      Some(Null) => None
      _ =>
        return incomplete(
          name + ": expected_command must be a nonempty string or null",
        )
    }
    let values : Map[String, Bool] = Map([])
    match get_field(probe, "context") {
      Some(Object(context)) =>
        for key, value in context {
          match value {
            True => values[key] = true
            False => values[key] = false
            _ =>
              return incomplete(name + ": nonboolean context value for " + key)
          }
        }
      _ =>
        return incomplete(name + ": context must be an explicit boolean object")
    }
    // Platform booleans are authoritative, not inferred from the build machine.
    for
      (key, flag) in [
        ("isWindows", platform == "windows"),
        ("isMac", platform == "mac"),
        ("isLinux", platform == "linux"),
      ] {
      if values.get(key) is Some(value) && value != flag {
        return incomplete(name + ": inconsistent platform context " + key)
      }
      values[key] = flag
    }
    let trace : Array[String] = []
    let mut actual : String? = None
    let mut winner = ""
    let mut reason = ""
    let mut pending = false
    for count in 1..<(input.steps.length() + 1) {
      let mut matched = false
      let mut index = rules.length() - 1
      while index >= 0 {
        let rule = rules[index]
        index -= 1
        if !prefix_matches(rule, input, count) {
          continue
        }
        let condition = match rule.condition {
          Ok(expr) => eval(expr, values)
          Err(error) => Err(error)
        }
        let outcome = match condition {
          Ok(true) => "true"
          Ok(false) => "false"
          Err(_) => "unknown"
        }
        trace.push(
          "{\"rule\":" +
          quote(rule.id) +
          ",\"when\":" +
          quote(rule.when_text) +
          ",\"condition\":" +
          quote(outcome) +
          ",\"command\":" +
          quote(rule.command) +
          ",\"step\":" +
          count.to_string() +
          "}",
        )
        if rule.unsupported != "" {
          reason = rule.id + ": " + rule.unsupported
          break
        }
        match condition {
          Err(error) => {
            reason = rule.id + ": " + error
            break
          }
          Ok(false) => continue
          Ok(true) => {
            matched = true
            winner = rule.id
            pending = rule.keys.steps.length() > count
            if !pending {
              actual = Some(rule.command)
            }
            break
          }
        }
      }
      if (actual is Some(_) || !matched) && count < input.steps.length() {
        reason = "sequence interrupted before its last chord; host replay required"
      }
      if reason != "" || actual is Some(_) || !matched {
        pending = false
        break
      }
    }
    if pending {
      reason = "partial chord requires additional input or host timing"
    }
    let status = if reason != "" {
      unknown += 1
      "inconclusive"
    } else if actual != expected {
      failed += 1
      "regression"
    } else {
      "pass"
    }
    rows.push(
      "{\"name\":" +
      quote(name) +
      ",\"key\":" +
      quote(raw) +
      ",\"status\":" +
      quote(status) +
      ",\"expected_command\":" +
      expected.map(quote).unwrap_or("null") +
      ",\"actual_command\":" +
      actual.map(quote).unwrap_or("null") +
      ",\"winner\":" +
      quote(winner) +
      ",\"reason\":" +
      quote(reason) +
      ",\"trace\":[" +
      trace.join(",") +
      "]}",
    )
  }
  let exit_code = if unknown > 0 { 2 } else if failed > 0 { 1 } else { 0 }
  let status = if unknown > 0 {
    "inconclusive"
  } else if failed > 0 {
    "regression"
  } else {
    "pass"
  }
  {
    json: "{\"profile\":\"vscode-ordered-boolean-v1\",\"scope\":\"supplied-rules-and-states-only\"," +
    "\"platform\":" +
    quote(platform) +
    ",\"status\":" +
    quote(status) +
    ",\"exit_code\":" +
    exit_code.to_string() +
    ",\"rules\":" +
    rules.length().to_string() +
    ",\"regressions\":" +
    failed.to_string() +
    ",\"inconclusive\":" +
    unknown.to_string() +
    ",\"cases\":[" +
    rows.join(",") +
    "]}",
    exit_code,
  }
}

///|
/// JS-exportable pure entrypoint: same engine, no subprocess or filesystem.
pub fn audit_json(
  defaults : String,
  extension : String,
  overrides : String,
  scenarios : String,
  platform : String,
) -> String {
  audit_sources(defaults, extension, overrides, scenarios, platform).json
}
