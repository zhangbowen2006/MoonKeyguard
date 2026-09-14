///|
/// Conflict graph utilities for finding keymap hotspots.
pub(all) struct ConflictEdge {
  left : String
  right : String
  code : String
  severity : Severity
  weight : Int
} derive(Eq, @debug.Debug)

///|
pub(all) struct ConflictNode {
  id : String
  command : String
  degree : Int
  error_degree : Int
  warning_degree : Int
  info_degree : Int
} derive(Eq, @debug.Debug)

///|
pub(all) struct ConflictGraph {
  nodes : Array[ConflictNode]
  edges : Array[ConflictEdge]
  components : Array[Array[String]]
} derive(Eq, @debug.Debug)

///|
fn edge_weight(severity : Severity) -> Int {
  match severity {
    Error => 5
    Warning => 3
    Info => 1
  }
}

///|
fn push_unique_string(items : Array[String], value : String) -> Unit {
  if !array_contains(items, value) {
    items.push(value)
  }
}

///|
fn make_edges(analysis : Analysis) -> Array[ConflictEdge] {
  let edges : Array[ConflictEdge] = []
  for finding in analysis.findings {
    if finding.secondary_id.length() > 0 {
      edges.push({
        left: finding.primary_id,
        right: finding.secondary_id,
        code: finding.code,
        severity: finding.severity,
        weight: edge_weight(finding.severity),
      })
    }
  }
  edges
}

///|
fn degree_for(edges : Array[ConflictEdge], id : String) -> (Int, Int, Int, Int) {
  let mut degree = 0
  let mut errors = 0
  let mut warnings = 0
  let mut infos = 0
  for edge in edges {
    if edge.left == id || edge.right == id {
      degree += 1
      match edge.severity {
        Error => errors += 1
        Warning => warnings += 1
        Info => infos += 1
      }
    }
  }
  (degree, errors, warnings, infos)
}

///|
fn neighbors(edges : Array[ConflictEdge], id : String) -> Array[String] {
  let result : Array[String] = []
  for edge in edges {
    if edge.left == id {
      push_unique_string(result, edge.right)
    } else if edge.right == id {
      push_unique_string(result, edge.left)
    }
  }
  result
}

///|
fn component_from(
  start : String,
  edges : Array[ConflictEdge],
  visited : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  let queue : Array[String] = [start]
  while queue.length() > 0 {
    let current = queue.remove(0)
    if array_contains(visited, current) {
      continue
    }
    visited.push(current)
    result.push(current)
    for neighbor in neighbors(edges, current) {
      if !array_contains(visited, neighbor) {
        queue.push(neighbor)
      }
    }
  }
  result.sort()
  result
}

///|
fn graph_components(
  nodes : Array[ConflictNode],
  edges : Array[ConflictEdge],
) -> Array[Array[String]] {
  let components : Array[Array[String]] = []
  let visited : Array[String] = []
  for node in nodes {
    if !array_contains(visited, node.id) {
      let component = component_from(node.id, edges, visited)
      components.push(component)
    }
  }
  components
}

///|
/// Build a graph from findings, retaining isolated bindings as nodes.
pub fn build_conflict_graph(
  keymap : Keymap,
  analysis : Analysis,
) -> ConflictGraph {
  let edges = make_edges(analysis)
  let nodes : Array[ConflictNode] = []
  for binding in keymap.bindings {
    let (degree, errors, warnings, infos) = degree_for(edges, binding.id)
    nodes.push({
      id: binding.id,
      command: binding.command,
      degree,
      error_degree: errors,
      warning_degree: warnings,
      info_degree: infos,
    })
  }
  { nodes, edges, components: graph_components(nodes, edges) }
}

///|
fn node_compare(left : ConflictNode, right : ConflictNode) -> Int {
  if left.degree > right.degree {
    -1
  } else if left.degree < right.degree {
    1
  } else if left.id < right.id {
    -1
  } else if left.id > right.id {
    1
  } else {
    0
  }
}

///|
/// Return nodes ranked by conflict degree, with stable id tie-breaking.
pub fn conflict_hotspots(
  graph : ConflictGraph,
  limit? : Int = 5,
) -> Array[ConflictNode] {
  let result = graph.nodes.copy()
  result.sort_by(node_compare)
  let maximum = if limit < 0 { 0 } else { limit }
  if result.length() > maximum {
    result[0:maximum].to_owned()
  } else {
    result
  }
}

///|
/// Return the component containing an id.
pub fn conflict_component(graph : ConflictGraph, id : String) -> Array[String] {
  for component in graph.components {
    if array_contains(component, id) {
      return component
    }
  }
  []
}

///|
pub fn conflict_graph_to_json(graph : ConflictGraph) -> String {
  let nodes : Array[String] = []
  let edges : Array[String] = []
  for node in graph.nodes {
    nodes.push(
      "{\"id\":" +
      json_string(node.id) +
      ",\"command\":" +
      json_string(node.command) +
      ",\"degree\":" +
      node.degree.to_string() +
      ",\"errors\":" +
      node.error_degree.to_string() +
      ",\"warnings\":" +
      node.warning_degree.to_string() +
      "}",
    )
  }
  for edge in graph.edges {
    edges.push(
      "{\"left\":" +
      json_string(edge.left) +
      ",\"right\":" +
      json_string(edge.right) +
      ",\"code\":" +
      json_string(edge.code) +
      ",\"severity\":" +
      json_string(edge.severity.name()) +
      ",\"weight\":" +
      edge.weight.to_string() +
      "}",
    )
  }
  "{\"nodes\":[" +
  nodes.join(",") +
  "],\"edges\":[" +
  edges.join(",") +
  "],\"components\":" +
  graph.components.length().to_string() +
  "}"
}

///|
pub fn conflict_graph_to_markdown(
  graph : ConflictGraph,
  limit? : Int = 10,
) -> String {
  let lines : Array[String] = [
    "## Conflict hotspots", "", "| Binding | Degree | Errors | Warnings |", "| --- | ---: | ---: | ---: |",
  ]
  for node in conflict_hotspots(graph, limit~) {
    lines.push(
      "| `" +
      node.id +
      "` | " +
      node.degree.to_string() +
      " | " +
      node.error_degree.to_string() +
      " | " +
      node.warning_degree.to_string() +
      " |",
    )
  }
  lines.push("")
  lines.push("Connected components: " + graph.components.length().to_string())
  lines.join("\n")
}
