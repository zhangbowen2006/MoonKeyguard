///|
/// Machine-readable schema and support matrix for integrations.
pub(all) struct FieldSpec {
  name : String
  required : Bool
  description : String
  example : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct KeymapSchema {
  version : String
  directives : Array[String]
  fields : Array[FieldSpec]
  formats : Array[String]
  guarantees : Array[String]
} derive(Eq, @debug.Debug)

///|
/// Describe the DSL consumed by `parse_keymap`.
pub fn keymap_schema() -> KeymapSchema {
  {
    version: "1",
    directives: ["keymap", "context", "reserve", "bind"],
    fields: [
      {
        name: "id",
        required: true,
        description: "stable binding identifier",
        example: "save",
      },
      {
        name: "command",
        required: true,
        description: "application command name",
        example: "editor.save",
      },
      {
        name: "keys",
        required: true,
        description: "one chord or comma-separated chord sequence",
        example: "Ctrl+K,Ctrl+L",
      },
      {
        name: "context",
        required: false,
        description: "context name inherited from global",
        example: "editor",
      },
      {
        name: "platform",
        required: false,
        description: "all or a platform list",
        example: "windows|linux",
      },
      {
        name: "priority",
        required: false,
        description: "higher priority wins at dispatch",
        example: "10",
      },
      {
        name: "enabled",
        required: false,
        description: "whether the binding is live",
        example: "true",
      },
      {
        name: "description",
        required: false,
        description: "review and accessibility explanation",
        example: "save buffer",
      },
    ],
    formats: [
      "MoonKeyguard DSL", "CSV", "TSV", "pipe adapter", "JSON report", "SARIF 2.1.0",
    ],
    guarantees: [
      "analysis does not mutate caller-owned arrays", "reports are deterministic for identical input",
      "unknown directives become parser diagnostics", "suggestions never reuse a reserved shortcut",
    ],
  }
}

///|
pub fn schema_to_json(schema : KeymapSchema) -> String {
  let fields : Array[String] = []
  for field in schema.fields {
    fields.push(
      "{\"name\":" +
      json_string(field.name) +
      ",\"required\":" +
      (if field.required { "true" } else { "false" }) +
      ",\"description\":" +
      json_string(field.description) +
      ",\"example\":" +
      json_string(field.example) +
      "}",
    )
  }
  "{\"version\":" +
  json_string(schema.version) +
  ",\"directives\":[" +
  schema.directives.map(json_string).join(",") +
  "],\"fields\":[" +
  fields.join(",") +
  "],\"formats\":[" +
  schema.formats.map(json_string).join(",") +
  "],\"guarantees\":[" +
  schema.guarantees.map(json_string).join(",") +
  "]}"
}

///|
pub fn schema_to_markdown(schema : KeymapSchema) -> String {
  let lines : Array[String] = [
    "## Keymap schema v" + schema.version,
    "",
    "Directives: `" + schema.directives.join("`, `") + "`",
    "",
    "| Field | Required | Description | Example |",
    "| --- | --- | --- | --- |",
  ]
  for field in schema.fields {
    lines.push(
      "| `" +
      field.name +
      "` | " +
      (if field.required { "yes" } else { "no" }) +
      " | " +
      field.description +
      " | `" +
      field.example +
      "` |",
    )
  }
  lines.push("")
  lines.push("Formats: " + schema.formats.join(", "))
  lines.push("")
  lines.push("### Guarantees")
  for guarantee in schema.guarantees {
    lines.push("- " + guarantee)
  }
  lines.join("\n")
}

///|
/// Return a stable feature matrix for README and downstream tooling.
pub fn support_matrix() -> Array[(String, String, Bool)] {
  [
    ("line-oriented DSL", "parser", true),
    ("exact conflict analysis", "analyzer", true),
    ("chord-prefix analysis", "analyzer", true),
    ("context inheritance", "resolver", true),
    ("platform overlap", "resolver", true),
    ("CSV import/export", "adapter", true),
    ("SARIF output", "report", true),
    ("operating-system runtime hook", "out-of-scope", false),
    ("GUI key capture", "out-of-scope", false),
  ]
}
