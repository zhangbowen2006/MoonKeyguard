///|
fn has_arg(args : Array[String], wanted : String) -> Bool {
  for arg in args {
    if arg == wanted {
      return true
    }
  }
  false
}

///|
fn value_after(
  args : Array[String],
  wanted : String,
  default : String,
) -> String {
  for i in 0..<args.length() {
    if args[i] == wanted && i + 1 < args.length() {
      return args[i + 1]
    }
  }
  default
}

///|
fn print_help() -> Unit {
  let help =
    #|MoonKeyguard — static keyboard shortcut analysis
    #|
    #|Usage:
    #|  moon run cmd/main
    #|  moon run cmd/main -- --source "bind save command=save keys=Ctrl+S"
    #|  moon run cmd/main -- --format json
    #|  moon run cmd/main -- --format markdown --suggest
    #|  moon run cmd/main -- --format sarif --fail-on-warning
    #|
    #|The CLI audits the bundled demo by default. Use --source for an inline
    #|keymap; library users can call parse_keymap(source) for larger files.
  println(help)
}

///|
fn print_diagnostics(parsed : @moonkeyguard.ParseResult) -> Unit {
  for diagnostic in parsed.diagnostics {
    println(
      "parse " +
      diagnostic.code +
      " line " +
      diagnostic.line.to_string() +
      ": " +
      diagnostic.message,
    )
  }
}

///|
fn main {
  let args = @env.args()
  if has_arg(args, "--help") || has_arg(args, "-h") {
    print_help()
    return
  }
  let requested_source = value_after(args, "--source", "")
  let source = if requested_source.length() == 0 {
    @moonkeyguard.demo_source()
  } else {
    requested_source
  }
  let name = value_after(args, "--name", "editor-demo")
  let (parsed, analysis) = @moonkeyguard.audit(source, name~)
  if parsed.diagnostics.length() > 0 {
    print_diagnostics(parsed)
  }
  let format = value_after(args, "--format", "text")
  if format == "json" {
    println(@moonkeyguard.analysis_to_json(analysis))
  } else if format == "markdown" || format == "md" {
    println(@moonkeyguard.analysis_to_markdown(analysis))
  } else if format == "sarif" {
    println(@moonkeyguard.analysis_to_sarif(analysis))
  } else {
    println(@moonkeyguard.analysis_to_text(analysis))
  }
  if has_arg(args, "--metrics") {
    println(
      @moonkeyguard.metrics_to_json(@moonkeyguard.keymap_metrics(parsed.keymap)),
    )
  }
  if has_arg(args, "--suggest") {
    let suggestions = @moonkeyguard.suggest_all(parsed.keymap, analysis)
    println(@moonkeyguard.suggestions_to_markdown(suggestions))
  }
  if has_arg(args, "--fail-on-warning") {
    let code = @moonkeyguard.analysis_exit_code(analysis, fail_on_warning=true)
    if code != 0 {
      println("CI gate: failed")
      @abort.abort("MoonKeyguard CI gate failed")
    }
  }
}
