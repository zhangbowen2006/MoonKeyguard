///|
/// Synchronous descriptor writes complete before process exit, including pipes.
#module("node:fs")
extern "js" fn write_stream(fd : Int, text : String) -> Unit = "writeFileSync"

///|
#external
priv type HostBytesResult

///|
extern "js" fn HostBytesResult::is_ok(self : Self) -> Bool =
  #| (result) => result.ok

///|
extern "js" fn HostBytesResult::bytes(self : Self) -> Bytes =
  #| (result) => result.value

///|
extern "js" fn HostBytesResult::message(self : Self) -> String =
  #| (result) => result.value

///|
#module("node:fs")
extern "js" fn node_read_file(path : String) -> Bytes = "readFileSync"

///|
extern "js" fn guarded_read_file(
  read_file : (String) -> Bytes,
  path : String,
) -> HostBytesResult =
  #| function(readFile, path) {
  #|   try {
  #|     return { ok: true, value: readFile(path) };
  #|   } catch (error) {
  #|     return { ok: false, value: String(error?.message ?? error) };
  #|   }
  #| }

///|
fn read_file_bytes(path : String) -> Result[Bytes, String] {
  let result = guarded_read_file(node_read_file, path)
  if result.is_ok() {
    Ok(result.bytes())
  } else {
    Err(result.message())
  }
}

///|
extern "js" fn exit_process(code : Int) -> Unit =
  #| (code) => process.exit(code)
