///|
/// Synchronous descriptor writes complete before @sys.exit, including pipes.
#module("node:fs")
extern "js" fn write_stream(fd : Int, text : String) -> Unit = "writeFileSync"
