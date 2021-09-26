#include "log.hpp"

#include <cstddef>
#include <cstdio>

#include "console.hpp"

namespace {
  LogLevel log_level=kLogInfo;
}

extern kConsole* kernel_console;

void SetLogLevel(LogLevel lev){
  log_level=lev;
}

int PutLog(LogLevel lev,const char* fmt,...){
  if(lev>log_level)return 0;
  va_list ap;
  int res;
  char buf[1024];

  va_start(ap,fmt);
  res=vsprintf(buf,fmt,ap);
  va_end(ap);

  kernel_console->PutStr(buf);
  return res;
}
