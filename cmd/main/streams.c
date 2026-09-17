/* Original, minimal C stdio glue for the native CLI; no analysis logic. */
#include <stdint.h>
#include <stdio.h>

void moonkeyguard_stream_byte(int32_t fd, int32_t byte) {
    fputc(byte, fd == 2 ? stderr : stdout);
}

void moonkeyguard_stream_flush(int32_t fd) {
    fflush(fd == 2 ? stderr : stdout);
}
