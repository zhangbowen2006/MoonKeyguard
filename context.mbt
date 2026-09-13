///|
/// Context hierarchy and platform overlap helpers.
fn context_index(keymap : Keymap, name : String) -> Int? {
  for i, context in keymap.contexts {
    if context.name == name {
      return Some(i)
    }
  }
  None
}

///|
fn context_by_name(keymap : Keymap, name : String) -> Context? {
  match context_index(keymap, name) {
    Some(index) => Some(keymap.contexts[index])
    None => None
  }
}

///|
fn context_exists(keymap : Keymap, name : String) -> Bool {
  context_index(keymap, name) is Some(_)
}

///|
fn context_is_ancestor(
  keymap : Keymap,
  ancestor : String,
  child : String,
) -> Bool {
  if ancestor == child {
    return true
  }
  let mut current = child
  let mut steps = 0
  while steps <= keymap.contexts.length() {
    match context_by_name(keymap, current) {
      Some(context) => {
        if context.parent.length() == 0 {
          return false
        }
        if context.parent == ancestor {
          return true
        }
        current = context.parent
      }
      None => return false
    }
    steps += 1
  }
  false
}

///|
/// Two contexts overlap when one is active inside the other. Sibling editor
/// modes intentionally do not conflict because only one can be active.
fn contexts_overlap(keymap : Keymap, left : String, right : String) -> Bool {
  context_is_ancestor(keymap, left, right) ||
  context_is_ancestor(keymap, right, left)
}

///|
fn platform_parts(platform : String) -> Array[String] {
  platform
  .replace(old="|", new=",")
  .split(",")
  .map(x => lower_ascii(trim_ascii(x.to_owned())))
  .filter(x => x.length() > 0)
  .to_array()
}

///|
fn platform_contains(platform : String, wanted : String) -> Bool {
  let values = platform_parts(platform)
  for value in values {
    if value == wanted || value == "all" {
      return true
    }
  }
  false
}

///|
/// Platform names are case-insensitive and can be combined with `|` or `,`.
pub fn platforms_overlap(left : String, right : String) -> Bool {
  let l = platform_parts(left)
  let r = platform_parts(right)
  if l.length() == 0 || r.length() == 0 {
    return true
  }
  for value in l {
    if platform_contains(right, value) {
      return true
    }
  }
  for value in r {
    if platform_contains(left, value) {
      return true
    }
  }
  false
}

///|
fn platform_label(platform : String) -> String {
  let clean = lower_ascii(trim_ascii(platform))
  if clean.length() == 0 {
    "all"
  } else {
    clean
  }
}

///|
fn reserved_matches(keymap : Keymap, binding : Binding) -> Bool {
  let canonical = binding.keys.canonical
  let platform = platform_label(binding.platform)
  for marker in keymap.reserved {
    let (marker_platform, marker_key) = split_once(marker, ":")
    if marker_key == canonical &&
      (
        marker_platform == "all" ||
        platform_contains(platform, marker_platform) ||
        platform_contains(marker_platform, platform)
      ) {
      return true
    }
  }
  false
}

///|
fn binding_context_rank(keymap : Keymap, binding : Binding) -> Int {
  match context_by_name(keymap, binding.context) {
    Some(context) => context.rank
    None => -1000
  }
}

///|
fn more_specific(keymap : Keymap, left : Binding, right : Binding) -> Binding {
  let left_rank = binding_context_rank(keymap, left)
  let right_rank = binding_context_rank(keymap, right)
  if left.priority > right.priority ||
    (left.priority == right.priority && left_rank >= right_rank) {
    left
  } else {
    right
  }
}

///|
fn context_chain(keymap : Keymap, name : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = name
  let mut steps = 0
  while current.length() > 0 && steps <= keymap.contexts.length() {
    result.push(current)
    match context_by_name(keymap, current) {
      Some(context) => current = context.parent
      None => current = ""
    }
    steps += 1
  }
  result
}

///|
/// Explain why two bindings are considered to overlap.
pub fn overlap_explanation(
  keymap : Keymap,
  left : Binding,
  right : Binding,
) -> String {
  let contexts = if left.context == right.context {
    "same context '" + left.context + "'"
  } else {
    "context chains " +
    context_chain(keymap, left.context).join(" > ") +
    " and " +
    context_chain(keymap, right.context).join(" > ")
  }
  let platforms = if lower_ascii(left.platform) == lower_ascii(right.platform) {
    "same platform " + platform_label(left.platform)
  } else {
    "platforms " +
    platform_label(left.platform) +
    " and " +
    platform_label(right.platform) +
    " overlap"
  }
  contexts + "; " + platforms
}
