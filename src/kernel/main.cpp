#include <cstdint>
#include <cstddef>
#include <cstdio>

#include "elf.hpp"
#include "memmap.hpp"
#include "fb_conf.hpp"
#include "graphics.hpp"
#include "font.hpp"
#include "console.hpp"

Console* kConsole;
char kConsole_buf[sizeof(Console)];

void* operator new(size_t s,void* buf){
  return buf;
}
void operator delete(void* obj){} // なんか要るらしい

int printk(const char* fmt,...){
  va_list ap;
  int res;
  char s[1024];

  va_start(ap,fmt);
  res=vsprintf(s,fmt,ap);
  va_end(ap);

  kConsole->PutStr(s);
  return res;
}

extern "C" void KernelMain(const FBConf& fbconf){
  InitValsFont();

  // pixel_writer
  PixelWriter* pixel_writer;
  char pixel_writer_buf[sizeof(PixelWriterRGB)];
  switch(fbconf.pixel_fmt){
    case kPixelRGB:
      pixel_writer = new(pixel_writer_buf) PixelWriterRGB(fbconf);
      break;
    case kPixelBGR:
      pixel_writer = new(pixel_writer_buf) PixelWriterBGR(fbconf);
      break;
  }

  // kConsole
  kConsole = new(kConsole_buf) Console(
      *pixel_writer,
      fbconf.res_horiz-8,
      fbconf.res_vert-8,
      4,4,
      {0,0,0},{0x20,0xff,0x20});

  // main loop

  printk("Hello.\n");

  while(1){
    __asm__("hlt");
  }
}
