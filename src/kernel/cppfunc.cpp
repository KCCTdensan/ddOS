#include <cstdio>
#include "display/console.hpp"

extern kConsole* kernel_console;

int printk(const char* fmt,...){
    va_list ap;
    int res;
    char s[1024];

    va_start(ap,fmt);
    res=vsprintf(s,fmt,ap);
    va_end(ap);

    kernel_console->PutStr(s);
    return res;
}