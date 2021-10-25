#pragma once

enum LogLevel { // log.d
  kLogError=3,
  kLogWarn =4,
  kLogInfo =6, // default
  kLogDebug=7,
};

void SetLogLevel(LogLevel);

int PutLog(LogLevel,const char* fmt,...);
