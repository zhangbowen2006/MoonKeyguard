///|
/// Pure CLI configuration. File access belongs to the executable, not the library.
pub(all) struct Options {
  input : String?
  source : String?
  baseline : String?
  name : String
  format : String
  metrics : Bool
  suggest : Bool
  fail_on_error : Bool
  fail_on_warning : Bool
  max_bindings : Int
  help : Bool
} derive(Eq, @debug.Debug)

///|
pub fn default_options() -> Options {
  {
    input: None,
    source: None,
    baseline: None,
    name: "keymap",
    format: "text",
    metrics: false,
    suggest: false,
    fail_on_error: false,
    fail_on_warning: false,
    max_bindings: 2000,
    help: false,
  }
}

///|
/// Parse arguments WITHOUT argv[0]. Reject typos, ambiguous inputs and duplicates.
pub fn parse_options(args : Array[String]) -> Result[Options, String] {
  let mut options = default_options()
  let seen : Map[String, Bool] = Map([])
  let mut i = 0
  // moon run may forward a leading separator; it is not a filename.
  if args.length() > 0 && args[0] == "--" {
    i = 1
  }
  while i < args.length() {
    let flag = if args[i] == "-h" { "--help" } else { args[i] }
    if seen.contains(flag) {
      return Err("option supplied more than once: " + flag)
    }
    seen[flag] = true
    match flag {
      "--help" => options = { ..options, help: true, }
      "--metrics" => options = { ..options, metrics: true, }
      "--suggest" => options = { ..options, suggest: true, }
      "--fail-on-error" => options = { ..options, fail_on_error: true, }
      "--fail-on-warning" => options = { ..options, fail_on_warning: true, }
      "--input"
      | "--source"
      | "--baseline"
      | "--name"
      | "--format"
      | "--max-bindings" => {
        if i + 1 >= args.length() || args[i + 1].has_prefix("--") {
          return Err("missing value for " + flag)
        }
        i += 1
        let value = args[i]
        if value.length() == 0 && flag != "--source" {
          return Err("empty value for " + flag)
        }
        match flag {
          "--input" => options = { ..options, input: Some(value), }
          "--source" => options = { ..options, source: Some(value), }
          "--baseline" => options = { ..options, baseline: Some(value), }
          "--name" => options = { ..options, name: value, }
          "--format" => {
            let format = if value == "md" { "markdown" } else { value }
            if !["text", "markdown", "json", "sarif"].contains(format) {
              return Err("unsupported format: " + value)
            }
            options = { ..options, format, }
          }
          "--max-bindings" => {
            let count = @string.parse_int(value) catch {
              _ =>
                return Err("--max-bindings must be an integer from 1 to 10000")
            }
            if count < 1 || count > 10000 {
              return Err("--max-bindings must be an integer from 1 to 10000")
            }
            options = { ..options, max_bindings: count, }
          }
          _ => ()
        }
      }
      _ => return Err("unknown argument: " + flag)
    }
    i += 1
  }
  if options.input is Some(_) && options.source is Some(_) {
    return Err("--input and --source cannot be used together")
  }
  if options.baseline is Some(_) &&
    options.input is None &&
    options.source is None {
    return Err("--baseline requires an explicit --input or --source")
  }
  if options.format == "sarif" &&
    (options.metrics || options.suggest || options.baseline is Some(_)) {
    return Err(
      "SARIF cannot be combined with --metrics, --suggest or --baseline; use JSON",
    )
  }
  Ok(options)
}

///|
pub fn help_text() -> String {
  let help =
    #|MoonKeyguard - offline shortcut auditing
    #|
    #|Usage: moon run cmd/main -- [options]
    #|  --input PATH           Read an explicitly named UTF-8 keymap (read-only)
    #|  --source TEXT          Use inline DSL; an empty value means an empty keymap
    #|  --baseline PATH        Compare with accepted DSL; fail only on NEW errors
    #|  --format FORMAT        text, markdown (md), json, sarif
    #|  --name NAME            Fallback document name
    #|  --metrics              Include binding/context metrics
    #|  --suggest              Include deterministic replacement suggestions
    #|  --fail-on-error        Exit 1 on analysis errors (default is report-only)
    #|  --fail-on-warning      Exit 1 on errors or warnings
    #|  --max-bindings N       Per-document safety limit: 1..10000, default 2000
    #|  --help, -h             Display help
    #|
    #|No input option: audit the bundled demonstration.
    #|JSON emits one object; human diagnostics are sent to stderr.
    #|Exit codes: 0 completed/pass, 1 policy gate failed, 2 input/usage/IO error.
    #|Files are read fully, limited to 2 MiB; stdin and automatic config discovery
    #|are not supported. Core analysis is quadratic: increase limits with care.
  help
}
