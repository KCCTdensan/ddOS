#include <cstdint>
#include <cstddef>

#include "elf.hpp"
#include "memmap.hpp"
#include "fb_conf.hpp"
#include "graphics.hpp"
#include "font.hpp"

void* operator new(size_t s,void* buf){
  return buf;
}
void operator delete(void* obj){} // なんか要るらしい

extern "C" void KernelMain(const FBConf& fbconf){

  // グラフィック

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
  for(int y=0;y<fbconf.res_vert;y++)
    for(int x=0;x<fbconf.res_horiz;x++)
      pixel_writer->Write(x,y,{0xe0,0xe0,0xe0});

  // main loop

  WriteFont(*pixel_writer,0,0,'A',{0,0,0});

  while(1){
    __asm__("hlt");
  }
}
