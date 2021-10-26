import display.console;
import lib.string;

enum LogLevel {
  Error = 3,
  Warn  = 4,
  Info  = 6, // default
  Debug = 7,
}

//int PutLog(T...)(KConsole console, LogLevel lev, string fmt, T args) {
//  if(lev>log_level) return 0;
//  int res;
//  char[1024] buf;
//  res = buf.tsprintf(fmt,args);
//  console.PutStr(buf);
//  return res;
//}
