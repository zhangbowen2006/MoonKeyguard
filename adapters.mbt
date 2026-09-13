///|
/// Dependency-free tabular adapters for importing keymaps from CI artifacts.
pub(all) struct BindingRow {
  id : String
  command : String
  keys : String
  context : String
  platform : String
  priority : String
  enabled : String
  description : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct ImportReport {
  keymap : Keymap
  rows_seen : Int
  rows_imported : Int
  diagnostics : Array[ParseDiagnostic]
} derive(Eq, @debug.Debug)

///|
fn csv_field(value : String) -> String {
  let needs_quote = value.contains(",") ||
    value.contains("\"") ||
    value.contains("\n")
  if needs_quote {
    "\"" + value.replace(old="\"", new="\"\"") + "\""
  } else {
    value
  }
}

///|
fn parse_csv_line(line : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = StringBuilder()
  let mut quoted = false
  let mut i = 0
  while i < line.length() {
    let code = line.unsafe_get(i).to_int()
    if code == 34 {
      if quoted &&
        i + 1 < line.length() &&
        line.unsafe_get(i + 1).to_int() == 34 {
        current.write_char('"')
        i += 2
        continue
      }
      quoted = !quoted
    } else if code == 44 && !quoted {
      result.push(current.to_string())
      current = StringBuilder()
    } else {
      current.write_char(line.unsafe_get(i).to_int().unsafe_to_char())
    }
    i += 1
  }
  result.push(current.to_string())
  result
}

///|
fn csv_header_index(headers : Array[String], wanted : String) -> Int {
  for i, header in headers {
    if lower_ascii(trim_ascii(header)) == wanted {
      return i
    }
  }
  -1
}

///|
fn csv_value(row : Array[String], index : Int, default : String) -> String {
  if index >= 0 && index < row.length() {
    trim_ascii(row[index])
  } else {
    default
  }
}

///|
/// Import the stable CSV schema emitted by `export_csv`.
pub fn import_csv(
  source : String,
  name? : String = "csv-keymap",
) -> ImportReport {
  let lines = source.split("\n").map(x => x.to_owned()).to_array()
  let diagnostics : Array[ParseDiagnostic] = []
  if lines.length() == 0 {
    return {
      keymap: Keymap::empty(name~),
      rows_seen: 0,
      rows_imported: 0,
      diagnostics: [
        {
          line: 1,
          code: "empty-csv",
          message: "CSV document is empty",
          source: "",
        },
      ],
    }
  }
  let headers = parse_csv_line(lines[0])
  let id_index = csv_header_index(headers, "id")
  let command_index = csv_header_index(headers, "command")
  let keys_index = csv_header_index(headers, "keys")
  if id_index < 0 || command_index < 0 || keys_index < 0 {
    diagnostics.push({
      line: 1,
      code: "missing-csv-columns",
      message: "CSV requires id, command, and keys columns",
      source: "header",
    })
  }
  let keymap = Keymap::empty(name~)
  let mut imported = 0
  for line_index in 1..<lines.length() {
    let line = trim_ascii(lines[line_index])
    if line.length() == 0 {
      continue
    }
    let row = parse_csv_line(line)
    let id = csv_value(row, id_index, "")
    let command = csv_value(row, command_index, "")
    let raw_keys = csv_value(row, keys_index, "")
    if id.length() == 0 || command.length() == 0 {
      diagnostics.push({
        line: line_index + 1,
        code: "missing-csv-value",
        message: "id and command are required",
        source: line,
      })
      continue
    }
    match parse_keys(raw_keys) {
      Err(message) =>
        diagnostics.push({
          line: line_index + 1,
          code: "invalid-csv-keys",
          message,
          source: id,
        })
      Ok(keys) => {
        let context = csv_value(
          row,
          csv_header_index(headers, "context"),
          "global",
        )
        let platform = csv_value(
          row,
          csv_header_index(headers, "platform"),
          "all",
        )
        let priority = int_value(
          csv_value(row, csv_header_index(headers, "priority"), "0"),
          0,
        )
        let enabled = bool_value(
          csv_value(row, csv_header_index(headers, "enabled"), "true"),
          true,
        )
        let description = csv_value(
          row,
          csv_header_index(headers, "description"),
          "",
        )
        if context != "global" && !context_exists(keymap, context) {
          keymap.contexts.push({
            name: context,
            parent: "global",
            rank: 1,
            description: "imported",
          })
        }
        keymap.bindings.push(
          Binding::new(
            id,
            command,
            keys,
            context~,
            platform~,
            source="csv",
            line=line_index + 1,
            priority~,
            enabled~,
            description~,
          ),
        )
        imported += 1
      }
    }
  }
  {
    keymap,
    rows_seen: if lines.length() > 0 {
      lines.length() - 1
    } else {
      0
    },
    rows_imported: imported,
    diagnostics,
  }
}

///|
/// Import tab-separated rows using the same column names as CSV.
pub fn import_tsv(
  source : String,
  name? : String = "tsv-keymap",
) -> ImportReport {
  import_csv(source.replace(old="\t", new=","), name~)
}

///|
/// Export a keymap using a stable, documented column order.
pub fn export_csv(keymap : Keymap) -> String {
  let lines : Array[String] = [
    "id,command,keys,context,platform,priority,enabled,description",
  ]
  for binding in normalize_keymap(keymap).bindings {
    let enabled = if binding.enabled { "true" } else { "false" }
    lines.push(
      [
        csv_field(binding.id),
        csv_field(binding.command),
        csv_field(binding.keys.canonical),
        csv_field(binding.context),
        csv_field(binding.platform),
        binding.priority.to_string(),
        enabled,
        csv_field(binding.description),
      ].join(","),
    )
  }
  lines.join("\n")
}

///|
/// A compact row constructor for integrations that already have columns.
pub fn row(
  id : String,
  command : String,
  keys : String,
  context? : String = "global",
  platform? : String = "all",
  priority? : String = "0",
  enabled? : String = "true",
  description? : String = "",
) -> BindingRow {
  { id, command, keys, context, platform, priority, enabled, description }
}

///|
/// Construct a keymap from rows and preserve row-level diagnostics.
pub fn import_rows(
  rows : Array[BindingRow],
  name? : String = "row-keymap",
) -> ImportReport {
  let keymap = Keymap::empty(name~)
  let diagnostics : Array[ParseDiagnostic] = []
  let mut imported = 0
  for index, item in rows {
    match parse_keys(item.keys) {
      Err(message) =>
        diagnostics.push({
          line: index + 1,
          code: "invalid-row-keys",
          message,
          source: item.id,
        })
      Ok(keys) => {
        let context = string_or_default(item.context, "global")
        if context != "global" && !context_exists(keymap, context) {
          keymap.contexts.push({
            name: context,
            parent: "global",
            rank: 1,
            description: "row-import",
          })
        }
        keymap.bindings.push(
          Binding::new(
            item.id,
            item.command,
            keys,
            context~,
            platform=string_or_default(item.platform, "all"),
            source="row",
            line=index + 1,
            priority=int_value(item.priority, 0),
            enabled=bool_value(item.enabled, true),
            description=item.description,
          ),
        )
        imported += 1
      }
    }
  }
  { keymap, rows_seen: rows.length(), rows_imported: imported, diagnostics }
}

///|
fn vscode_context(when : String) -> String {
  let clean = lower_ascii(trim_ascii(when))
  if clean.length() == 0 || clean == "editortextfocus" || clean == "editorfocus" {
    "editor"
  } else {
    "global"
  }
}

///|
/// Import a deliberately small VS Code-style line format:
/// `command | key | when | platform`.
pub fn import_pipe(
  source : String,
  name? : String = "pipe-keymap",
) -> ImportReport {
  let rows : Array[BindingRow] = []
  let lines = source.split("\n").map(x => x.to_owned()).to_array()
  for line in lines {
    let clean = trim_ascii(line)
    if clean.length() == 0 || clean[0] == '#' {
      continue
    }
    let fields = clean.split("|").map(x => trim_ascii(x.to_owned())).to_array()
    if fields.length() >= 2 {
      let command = fields[0]
      let keys = fields[1]
      let context = if fields.length() > 2 {
        vscode_context(fields[2])
      } else {
        "global"
      }
      let platform = if fields.length() > 3 { fields[3] } else { "all" }
      rows.push(
        row(
          command,
          command,
          keys,
          context~,
          platform~,
          description="pipe import",
        ),
      )
    }
  }
  import_rows(rows, name~)
}

///|
pub fn import_report_to_text(report : ImportReport) -> String {
  let lines : Array[String] = [
    "imported " +
    report.rows_imported.to_string() +
    "/" +
    report.rows_seen.to_string() +
    " rows",
    "keymap=" +
    report.keymap.name +
    " bindings=" +
    report.keymap.bindings.length().to_string(),
  ]
  for diagnostic in report.diagnostics {
    lines.push(
      "line " +
      diagnostic.line.to_string() +
      " " +
      diagnostic.code +
      ": " +
      diagnostic.message,
    )
  }
  lines.join("\n")
}
