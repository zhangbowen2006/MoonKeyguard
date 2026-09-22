///|
fn main {
  let source = @moonkeyguard.clean_demo_source()
  let (parsed, analysis) = @moonkeyguard.audit(source, name="basic-example")
  println("MoonKeyguard basic example")
  println("parser_ok=" + parsed.ok.to_string())
  println(@moonkeyguard.analysis_to_text(analysis))
  let graph = @moonkeyguard.build_conflict_graph(parsed.keymap, analysis)
  println(@moonkeyguard.conflict_graph_to_markdown(graph))
  let trace = @moonkeyguard.replay(
    parsed.keymap,
    ["Ctrl+S", "Ctrl+Z"],
    context="editor",
  )
  println(@moonkeyguard.dispatch_trace_to_markdown(trace))
  let reachability = @moonkeyguard.reachability_matrix(
    parsed.keymap,
    contexts=["global", "editor", "terminal"],
    platforms=["all", "mac"],
  )
  println(@moonkeyguard.reachability_to_markdown(reachability))
  let gate = @moonkeyguard.release_gate(
    "basic-example",
    "0.3.0",
    @moonkeyguard.release_input(parsed.keymap),
  )
  println(@moonkeyguard.release_gate_to_markdown(gate))
}
