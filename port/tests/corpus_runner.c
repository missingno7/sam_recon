#include "pc/platform.h"
void s1_run(void);
int main(int argc,char **argv)
{
    if(!platform_init(argc,argv)) return 2;
    int status=platform_run(s1_run);
    platform_shutdown();return status;
}
