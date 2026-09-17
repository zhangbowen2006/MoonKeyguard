///|
/// Read only a user-supplied regular file. No directory traversal or discovery.
fn read_keymap(path : String) -> Result[String, String] {
  let regular = @fs.is_file(path) catch {
    @fs.IOError(message) => return Err(path + ": " + message)
  }
  if !regular {
    return Err(path + ": expected a regular file")
  }
  let bytes = @fs.read_file_to_bytes(path) catch {
    @fs.IOError(message) => return Err(path + ": " + message)
  }
  if bytes.length() > 2097152 {
    return Err(
      path + ": file exceeds 2 MiB (file is read before checking size)",
    )
  }
  let content = @utf8.decode(bytes[:]) catch {
    _ => return Err(path + ": invalid UTF-8; save the keymap as UTF-8")
  }
  Ok(content)
}

///|
fn run(args : Array[String]) -> @cli.Response {
  if args.length() > 0 && args[0] == "vscode" {
    return run_vscode(args[1:].to_owned())
  }
  let mut settings = match @cli.parse_options(args) {
    Ok(settings) => settings
    Err(message) => return @cli.input_error(message)
  }
  if settings.help {
    return { stdout: @cli.help_text(), stderr: "", exit_code: 0, }
  }
  let source = match (settings.input, settings.source) {
    (Some(path), _) => {
      if !args.contains("--name") {
        settings = { ..settings, name: path, }
      }
      match read_keymap(path) {
        Ok(text) => text
        Err(message) => return @cli.input_error(message, format=settings.format)
      }
    }
    (None, Some(text)) => text
    (None, None) => @kit.demo_source()
  }
  match settings.baseline {
    None => @cli.evaluate(settings, source)
    Some(path) =>
      match read_keymap(path) {
        Ok(text) => @cli.evaluate(settings, source, baseline_source=text)
        Err(message) => @cli.input_error(message, format=settings.format)
      }
  }
}

///|
#cfg(target="js")
fn argument_offset() -> Int {
  2
}

///|
#cfg(not(target="js"))
fn argument_offset() -> Int {
  1
}

///|
fn main {
  let args = @env.args()
  let offset = argument_offset()
  let response = run(
    if args.length() >= offset {
      args[offset:].to_owned()
    } else {
      []
    },
  )
  if response.stdout != "" {
    write_stream(1, response.stdout + "\n")
  }
  if response.stderr != "" {
    write_stream(2, response.stderr + "\n")
  }
  @sys.exit(response.exit_code)
}
