///|
/// The complete side-effect-free result. Hosts choose how to write the streams.
pub(all) struct Response {
  stdout : String
  stderr : String
  exit_code : Int
} derive(Eq, @debug.Debug)

///|
fn quote(text : String) -> String {
  Json::string(text).stringify()
}

///|
/// All usage/IO/parse failures have status 2, independently of policy flags.
pub fn input_error(message : String, format? : String = "text") -> Response {
  {
    stdout: if format == "json" {
      "{\"schema_version\":1,\"ok\":false,\"exit_code\":2,\"error\":" +
      quote(message) +
      "}"
    } else {
      ""
    },
    stderr: "MoonKeyguard: " + message,
    exit_code: 2,
  }
}

///|
fn parse_document(
  text : String,
  name : String,
  maximum : Int,
) -> Result[@kit.Keymap, String] {
  if maximum < 1 || maximum > 10000 {
    return Err("binding limit must be from 1 to 10000")
  }
  if text.length() > 1048576 {
    return Err(name + ": input exceeds 1048576 UTF-16 code units")
  }
  // Accept a UTF-8 BOM decoded by a host, including the inline/API path.
  let source = if text.length() > 0 && text.unsafe_get(0).to_int() == 65279 {
    text[1:].to_owned()
  } else {
    text
  }
  let parsed = @kit.parse_keymap(source, name~)
  if !parsed.ok {
    let messages = parsed.diagnostics.map(d => {
      name + ":" + d.line.to_string() + ": " + d.code + ": " + d.message
    })
    return Err(messages.join("\n"))
  }
  if parsed.keymap.bindings.length() > maximum {
    return Err(
      name + ": binding count exceeds --max-bindings " + maximum.to_string(),
    )
  }
  Ok(parsed.keymap)
}

///|
fn suggestion_json(item : @kit.Suggestion) -> String {
  "{\"binding_id\":" +
  quote(item.binding_id) +
  ",\"command\":" +
  quote(item.command) +
  ",\"current\":" +
  quote(item.current) +
  ",\"replacement\":" +
  quote(item.replacement) +
  ",\"reason\":" +
  quote(item.reason) +
  ",\"confidence\":" +
  item.confidence.to_string() +
  "}"
}

///|
/// Evaluate supplied documents; no filesystem, clock, environment or exit calls.
/// Input errors never compare a partial/invalid baseline as accepted debt.
pub fn evaluate(
  options : Options,
  source : String,
  baseline_source? : String,
) -> Response {
  if options.help {
    return { stdout: help_text(), stderr: "", exit_code: 0, }
  }
  let keymap = match
    parse_document(source, options.name, options.max_bindings) {
    Ok(keymap) => keymap
    Err(message) => return input_error(message, format=options.format)
  }
  let baseline_keymap = match (options.baseline, baseline_source) {
    (Some(name), Some(text)) =>
      match parse_document(text, name, options.max_bindings) {
        Ok(parsed) => Some(parsed)
        Err(message) => return input_error(message, format=options.format)
      }
    (None, None) => None
    _ =>
      return input_error(
        "baseline option and supplied baseline must agree",
        format=options.format,
      )
  }
  let analysis = @kit.analyze(keymap)
  let baseline = baseline_keymap.map(previous => {
    @kit.compare_baseline(
      @kit.analyze(previous),
      analysis,
      fail_on_warning=options.fail_on_warning,
    )
  })
  let exit_code = match baseline {
    Some(report) => if report.passed { 0 } else { 1 }
    None =>
      if options.fail_on_error || options.fail_on_warning {
        @kit.analysis_exit_code(
          analysis,
          fail_on_warning=options.fail_on_warning,
        )
      } else {
        0
      }
  }
  let suggestions = if options.suggest {
    @kit.suggest_all(keymap, analysis)
  } else {
    []
  }
  let output = match options.format {
    "json" =>
      "{\"schema_version\":1,\"ok\":" +
      (if exit_code == 0 { "true" } else { "false" }) +
      ",\"exit_code\":" +
      exit_code.to_string() +
      ",\"analysis\":" +
      @kit.analysis_to_json(analysis) +
      ",\"metrics\":" +
      (if options.metrics {
        @kit.metrics_to_json(@kit.keymap_metrics(keymap))
      } else {
        "null"
      }) +
      ",\"suggestions\":[" +
      suggestions.map(suggestion_json).join(",") +
      "]" +
      ",\"baseline\":" +
      (match baseline {
        Some(report) => @kit.baseline_report_to_json(report)
        None => "null"
      }) +
      "}"
    "sarif" => @kit.analysis_to_sarif(analysis)
    _ => {
      let blocks = [
        if options.format == "markdown" {
          @kit.analysis_to_markdown(analysis)
        } else {
          @kit.analysis_to_text(analysis)
        },
      ]
      if options.metrics {
        blocks.push(@kit.metrics_to_json(@kit.keymap_metrics(keymap)))
      }
      if options.suggest {
        blocks.push(@kit.suggestions_to_markdown(suggestions))
      }
      if baseline is Some(report) {
        blocks.push(@kit.baseline_report_to_markdown(report))
      }
      blocks.join("\n\n")
    }
  }
  {
    stdout: output,
    stderr: if exit_code == 1 {
      "MoonKeyguard: policy gate failed"
    } else {
      ""
    },
    exit_code,
  }
}
