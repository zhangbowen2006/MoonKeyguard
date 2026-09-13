/// A realistic sample used by the README, CLI, and regression tests.

///|
/// The sample intentionally contains one exact conflict, one chord-prefix
/// warning, one reserved shortcut, and one disabled entry.
pub fn demo_source() -> String {
  let source =
    #|keymap name=editor-demo version=1
    #|context global parent= rank=0 description=all-windows
    #|context editor parent=global rank=10 description=text-editor
    #|context terminal parent=global rank=10 description=terminal-pane
    #|reserve Ctrl+Alt+Delete platform=all
    #|reserve Cmd+Q platform=mac
    #|bind save command=editor.save keys=Ctrl+S context=editor platform=all priority=10 description=save-buffer
    #|bind save_as command=editor.save_as keys=Ctrl+Shift+S context=editor platform=all priority=10 description=save-as
    #|bind quick_open command=editor.quick_open keys=Ctrl+P context=editor platform=all priority=10 description=quick-open
    #|bind palette command=editor.palette keys=Ctrl+P context=editor platform=all priority=20 description=command-palette
    #|bind chord_prefix command=editor.jump keys=Ctrl+K context=editor platform=all priority=5 description=jump-prefix
    #|bind chord_full command=editor.jump_line keys=Ctrl+K,Ctrl+L context=editor platform=all priority=5 description=jump-line
    #|bind terminal_interrupt command=terminal.interrupt keys=Ctrl+C context=terminal platform=all priority=10 description=interrupt
    #|bind quit command=app.quit keys=Cmd+Q context=global platform=mac priority=1 description=quit
    #|bind dangerous command=app.reset keys=Ctrl+Alt+Delete context=global platform=all priority=1 description=reserved-demo
    #|bind legacy command=editor.legacy keys=Alt+L context=editor platform=all enabled=false description=kept-for-migration
  source
}

///|
/// A clean sample useful for embedding in a smoke test.
pub fn clean_demo_source() -> String {
  let source =
    #|keymap name=clean-demo version=1
    #|context global parent= rank=0 description=all-windows
    #|context editor parent=global rank=10 description=text-editor
    #|bind save command=editor.save keys=Ctrl+S context=editor platform=all priority=10 description=save-buffer
    #|bind palette command=editor.palette keys=Ctrl+Shift+P context=editor platform=all priority=10 description=command-palette
    #|bind terminal_interrupt command=terminal.interrupt keys=Ctrl+C context=global platform=all priority=10 description=interrupt
  source
}

///|
/// Build a sample keymap directly, avoiding a parser round trip for embedding.
pub fn demo_keymap() -> Keymap {
  parse_keymap(demo_source(), name="editor-demo").keymap
}

///|
/// Run the full sample audit.
pub fn demo_analysis() -> Analysis {
  analyze(demo_keymap())
}

///|
/// Explain the design boundary in machine-readable form.
pub fn project_capabilities() -> Array[String] {
  [
    "parse a review-friendly line-oriented keymap DSL", "canonicalize platform-specific modifier spelling",
    "detect exact and chord-prefix conflicts across context trees", "flag reserved shortcuts and modifierless accessibility risks",
    "suggest deterministic free replacement chords", "render text, Markdown, JSON, and SARIF reports",
  ]
}
