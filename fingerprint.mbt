///|
/// Small deterministic digest used to identify an analyzed keymap. This is not
/// a cryptographic signature; it is deliberately portable across targets.
fn digest_mix(state : UInt64, value : UInt64) -> UInt64 {
  let mixed = state ^ value
  mixed * 1099511628211
}

///|
fn digest_text(seed : UInt64, text : String) -> UInt64 {
  let mut state = seed
  for i in 0..<text.length() {
    state = digest_mix(state, text.unsafe_get(i).to_int().to_uint64())
  }
  state
}

///|
fn digest_hex(value : UInt64) -> String {
  let digits : Array[String] = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f",
  ]
  let chars : Array[String] = []
  let mut current = value
  let mut i = 0
  while i < 16 {
    let digit = (current & 15).to_int()
    chars.push(digits[digit])
    current = current >> 4
    i += 1
  }
  chars.rev().join("")
}

///|
fn keymap_fingerprint(keymap : Keymap) -> String {
  let mut state : UInt64 = 1469598103934665603
  state = digest_text(state, keymap.name)
  state = digest_text(state, keymap.version)
  for context in keymap.contexts {
    state = digest_text(state, context.name)
    state = digest_text(state, context.parent)
    state = digest_mix(state, context.rank.to_uint64())
  }
  for binding in keymap.bindings {
    state = digest_text(state, binding.id)
    state = digest_text(state, binding.command)
    state = digest_text(state, binding.keys.canonical)
    state = digest_text(state, binding.context)
    state = digest_text(state, binding.platform)
    state = digest_mix(state, binding.priority.to_uint64())
  }
  digest_hex(state)
}
