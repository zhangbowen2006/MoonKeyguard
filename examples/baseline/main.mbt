///|
fn main {
  let baseline_source =
    #|context editor parent=global rank=1 description=editor
    #|bind save command=editor.save keys=Ctrl+S context=editor
    #|bind undo command=editor.undo keys=Ctrl+Z context=editor
    #|bind prefix command=editor.prefix keys=Ctrl+K context=editor
  let current_source =
    #|context editor parent=global rank=1 description=editor
    #|bind save command=editor.save keys=Ctrl+S context=editor
    #|bind undo command=editor.undo keys=Ctrl+Z context=editor
    #|bind prefix command=editor.prefix keys=Ctrl+K context=editor
    #|bind chord command=editor.chord keys=Ctrl+K,Ctrl+L context=editor
  let baseline = @moonkeyguard.analyze(
    @moonkeyguard.parse_keymap(baseline_source, name="baseline").keymap,
  )
  let current = @moonkeyguard.analyze(
    @moonkeyguard.parse_keymap(current_source, name="current").keymap,
  )
  let report = @moonkeyguard.compare_baseline(baseline, current)
  println("MoonKeyguard baseline example")
  println(report.summary())
  println(@moonkeyguard.baseline_report_to_markdown(report))
}
