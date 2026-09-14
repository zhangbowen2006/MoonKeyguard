# Changelog

All notable changes to MoonKeyguard are recorded here. Entries describe real
repository changes; release links and package status are recorded only after
verification.

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