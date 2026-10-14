#include "pc/platform.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

void s1_run(void);
void s2_run(void);
void s3_run(void);
int main(int argc,char **argv)
{
#ifdef _WIN32
    SetErrorMode(SEM_FAILCRITICALERRORS|SEM_NOGPFAULTERRORBOX);
#endif
    int episode=1;
    char **platform_argv=calloc((size_t)argc+1,sizeof *platform_argv);
    if(!platform_argv) return 2;
    int n=0;platform_argv[n++]=argv[0];
    for(int i=1;i<argc;++i) {
        if(!strcmp(argv[i],"--episode")) {
            if(i+1==argc || strlen(argv[i+1])!=1 || argv[i+1][0]<'1' || argv[i+1][0]>'3') {
                fputs("--episode requires 1, 2 or 3.\n",stderr);free(platform_argv);return 2;
            }
            episode=argv[++i][0]-'0';
        }
        else platform_argv[n++]=argv[i];
    }
    const pc_code_fn episodes[]={s1_run,s2_run,s3_run};
    if(!platform_init(n,platform_argv)) {free(platform_argv);return 2;}
    int status=platform_run(episodes[episode-1]);
    printf("SAM%d exit=%d time_us=%llu irq0=%llu irq1=%llu\n",episode,status,
           (unsigned long long)pc_time_us(),(unsigned long long)pc_irq_count(8),
           (unsigned long long)pc_irq_count(9));
    platform_shutdown();free(platform_argv);return status;
}
