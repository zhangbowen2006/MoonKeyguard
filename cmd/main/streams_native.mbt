///|
extern "c" fn write_byte(fd : Int, byte : Int) -> Unit = "moonkeyguard_stream_byte"

///|
extern "c" fn flush_stream(fd : Int) -> Unit = "moonkeyguard_stream_flush"

///|
fn write_stream(fd : Int, text : String) -> Unit {
  let bytes = @utf8.encode(text)
  for byte in bytes {
    write_byte(fd, byte.to_int())
  }
  flush_stream(fd)
}

///|
/// Native execution is not part of the current acceptance target. Keep inline
/// CLI use available while returning an explicit error for file input.
fn read_file_bytes(_path : String) -> Result[Bytes, String] {
  Err("file input is not available in the native build; use the wasm or JS CLI")
}

///|
extern "c" fn exit_process(code : Int) -> Unit = "exit"
