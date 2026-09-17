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
