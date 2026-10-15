/* A completed translated program must not leave DOS sync registrations pointing
   into returned C frames. FILELIFE exercises recursive local files then Intr. */
#include "generated.h"
#include "pc/platform.h"
#include <stdio.h>

int main(int argc, char **argv) {
    if (!platform_init(argc, argv)) return 2;
    uint16_t baseline = tp_FrameBegin();
    int rc = platform_run(s1_run);
    if (rc || tp_FrameBegin() != baseline) {
        fputs("FAIL: returned local files remain registered with DOS sync\n", stderr);
        platform_shutdown();
        return 1;
    }
    platform_shutdown();
    puts("PASS: local-file registrations end with their translated frames");
    return 0;
}
