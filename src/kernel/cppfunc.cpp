#include <cstdint>
// #include <cstdio>

alignas(16) // dでやったらリンクエラー
uint8_t kernel_main_stack[1024 * 1024];

// int sprintf(const char* fmt, ...) {
//   va_list args;
//   int res;
//   char buf[1024];

//   va_start(args, fmt);
//   res = vsprintf(buf, fmt, args);
//   va_end(args);
// }

// int sprintk(const char* fmt,...){
//     va_list ap;
//     int res;
//     char s[1024];

//     va_start(ap,fmt);
//     res=vsprintf(s,fmt,ap);
//     va_end(ap);

//     kernel_console->PutStr(s);
//     return res;
// }
