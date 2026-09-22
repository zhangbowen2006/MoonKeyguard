// Portions adapted from moonbitlang/x, Copyright 2025 International Digital
// Economy Academy, licensed under the Apache License, Version 2.0.
// MoonKeyguard-specific stream and Result wrappers are project code.

///|
/// moonrun host ABI, not a standalone WASI guarantee; see THIRD_PARTY_NOTICES.
fn host_write_char(fd : Int, value : Int) -> Unit = "__moonbit_io_unstable" "write_char"

///|
fn host_flush(fd : Int) -> Unit = "__moonbit_io_unstable" "flush"

///|
fn write_stream(fd : Int, text : String) -> Unit {
  for ch in text.iter() {
    host_write_char(fd, ch.to_int())
  }
  host_flush(fd)
}

// The file bridge below is adapted from the read-only subset of
// moonbitlang/x@0.5.4 fs/fs_wasm.mbt (Apache-2.0). See THIRD_PARTY_NOTICES.md.

///|
#external
priv type HostStringCreateHandle

///|
#external
priv type HostStringReadHandle

///|
#external
priv type HostExternString

///|
fn begin_create_string() -> HostStringCreateHandle = "__moonbit_fs_unstable" "begin_create_string"

///|
fn append_string_char(handle : HostStringCreateHandle, char : Char) -> Unit = "__moonbit_fs_unstable" "string_append_char"

///|
fn finish_create_string(handle : HostStringCreateHandle) -> HostExternString = "__moonbit_fs_unstable" "finish_create_string"

///|
fn host_string(text : String) -> HostExternString {
  let handle = begin_create_string()
  for index = 0; index < text.length(); index = index + 1 {
    append_string_char(handle, UInt16::unsafe_to_char(text.code_unit_at(index)))
  }
  finish_create_string(handle)
}

///|
fn begin_read_string(text : HostExternString) -> HostStringReadHandle = "__moonbit_fs_unstable" "begin_read_string"

///|
fn read_string_char(handle : HostStringReadHandle) -> Int = "__moonbit_fs_unstable" "string_read_char"

///|
fn finish_read_string(handle : HostStringReadHandle) -> Unit = "__moonbit_fs_unstable" "finish_read_string"

///|
fn moon_string(text : HostExternString) -> String {
  let builder = StringBuilder()
  let handle = begin_read_string(text)
  while true {
    let value = read_string_char(handle)
    if value == -1 {
      break
    }
    builder.write_char(Int::unsafe_to_char(value))
  }
  finish_read_string(handle)
  builder.to_string()
}

///|
#external
priv type HostByteArrayReadHandle

///|
#external
priv type HostExternByteArray

///|
fn begin_read_byte_array(
  bytes : HostExternByteArray,
) -> HostByteArrayReadHandle = "__moonbit_fs_unstable" "begin_read_byte_array"

///|
fn read_byte(handle : HostByteArrayReadHandle) -> Int = "__moonbit_fs_unstable" "byte_array_read_byte"

///|
fn finish_read_byte_array(handle : HostByteArrayReadHandle) -> Unit = "__moonbit_fs_unstable" "finish_read_byte_array"

///|
fn moon_bytes(bytes : HostExternByteArray) -> Bytes {
  let values = []
  let handle = begin_read_byte_array(bytes)
  while true {
    let value = read_byte(handle)
    if value == -1 {
      break
    }
    values.push(value.to_byte())
  }
  finish_read_byte_array(handle)
  Bytes::from_array(values)
}

///|
fn host_error() -> HostExternString = "__moonbit_fs_unstable" "get_error_message"

///|
fn host_file_content() -> HostExternByteArray = "__moonbit_fs_unstable" "get_file_content"

///|
fn host_read_file(path : HostExternString) -> Int = "__moonbit_fs_unstable" "read_file_to_bytes_new"

///|
fn read_file_bytes(path : String) -> Result[Bytes, String] {
  if host_read_file(host_string(path)) == -1 {
    Err(moon_string(host_error()))
  } else {
    Ok(moon_bytes(host_file_content()))
  }
}

///|
fn exit_process(code : Int) -> Unit = "__moonbit_sys_unstable" "exit"
