# Changelog

All notable changes to MoonKeyguard are recorded here. Entries describe real
repository changes; release links and package status are recorded only after
verification.

## 0.3.0 — 2026-09-22

- Updated explicit trait-method promotions, black-box test qualification and
  test-only imports for MoonBit 0.10.14 strict warning checks.
- Reframed the submission around scoped VS Code extension dispatch contracts,
  not a claim of a universal host-independent keyboard resolver.
- Added native contribution/keybindings imports, ordered rule selection,
  platform overrides, explicit boolean context evaluation, decision traces and
  conservative inconclusive results for unsupported host behavior.
- Added one pure MoonBit kernel consumed by the file CLI and an exported JS API,
  plus an original development-host extension fixture and injected-regression
  scenarios. Cross-consumer checks are not claimed as live VS Code verification.
- Corrected the legacy pipe importer: unknown conditions no longer become
  global; empty conditions remain global; boolean OR cannot become extra fields.

- Added explicit read-only UTF-8 file input and baseline-file regression gates.
- Added a separately tested pure CLI policy package, strict argument validation,
  configurable binding limits, and distinct 0/1/2 process exit codes.
- Fixed empty inline input falling back to the demo and malformed DSL reporting
  success without a policy flag; expected errors no longer use abort.
- CLI JSON is now one schema-versioned document, including metrics, suggestions
  and baseline results; core analysis JSON APIs remain unchanged.
- Added original editor/plugin regression and repair fixtures, subprocess
  checks for wasm/wasm-gc/JS, and actual monotonic-clock scale measurements.
- Replaced the registry runtime dependency with a pure MoonBit JSONC normalizer,
  core JSON parsing and documented target-specific IO/exit adapters, allowing a
  clean extracted package to pass `moon publish --frozen` validation.

## 0.2.0 — 2026-09-14

- Added a deterministic context/platform reachability matrix that reports the
  selected, shadowed, ambiguous, unavailable, and disabled state of each binding.
- Corrected dispatcher and selection queries to use directional context
  inheritance: parent bindings apply to children, but child bindings do not leak
  into a parent context.
- Made `--fail-on-warning` block on parser diagnostics as well as analysis
  findings, so malformed keymaps cannot pass a CI gate silently.
- Added four reachability tests and expanded the suite to 89 deterministic tests.
- Updated the public API snapshot and formatted sources with the current MoonBit
  toolchain.

## 0.1.0 — 2026-09-13

- Created the independent September Hackathon project.
- Added the line-oriented keymap DSL and canonical shortcut parser.
- Added exact, prefix, context, platform, reserved-key and accessibility rules.
- Added suggestions, conflict graph, semantic diff, CSV/TSV/pipe adapters,
  policy profiles, structural validation, dispatcher replay and release gates.
- Added JSON, Markdown, text, SARIF and schema outputs.
- Added 85 deterministic tests, runnable examples and GitHub Actions CI.
