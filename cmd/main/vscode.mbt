///|
fn run_vscode(args : Array[String]) -> @cli.Response {
  if args == ["--help"] || args == ["-h"] {
    return {
      stdout: "moon run cmd/main -- vscode --defaults FILE --extension package.json --scenarios FILE --platform windows|mac|linux [--overrides keybindings.json]\nOutputs a scoped JSON contract report. Exit: 0 pass, 1 regression, 2 inconclusive/input error.",
      stderr: "",
      exit_code: 0,
    }
  }
  let options : Map[String, String] = Map([])
  let mut i = 0
  while i < args.length() {
    let flag = args[i]
    if ![
        "--defaults", "--extension", "--scenarios", "--overrides", "--platform",
      ].contains(flag) ||
      options.contains(flag) ||
      i + 1 >= args.length() ||
      args[i + 1].has_prefix("--") ||
      args[i + 1] == "" {
      return @cli.input_error(
        "unknown, duplicate or incomplete vscode option: " + flag,
      )
    }
    options[flag] = args[i + 1]
    i += 2
  }
  for required in ["--defaults", "--extension", "--scenarios", "--platform"] {
    if !options.contains(required) {
      return @cli.input_error("vscode requires " + required)
    }
  }
  let contents : Map[String, String] = Map([])
  for key in ["--defaults", "--extension", "--scenarios", "--overrides"] {
    if options.get(key) is Some(path) {
      match read_keymap(path) {
        Ok(text) => contents[key] = text
        Err(error) => return @cli.input_error(error, format="json")
      }
    }
  }
  let result = @vscode.audit_sources(
    contents.get("--defaults").unwrap(),
    contents.get("--extension").unwrap(),
    contents.get("--overrides").unwrap_or("[]"),
    contents.get("--scenarios").unwrap(),
    options.get("--platform").unwrap(),
  )
  {
    stdout: result.json,
    stderr: match result.exit_code {
      0 => ""
      1 =>
        "MoonKeyguard: VS Code dispatch contract regression; see cases and trace"
      _ =>
        "MoonKeyguard: inconclusive or invalid host input; this is not a PASS"
    },
    exit_code: result.exit_code,
  }
}
