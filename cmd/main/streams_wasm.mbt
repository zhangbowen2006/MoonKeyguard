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
