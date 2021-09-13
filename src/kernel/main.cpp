#include <cstdint>
#include <cstddef>

#include "elf.hpp"
#include "memmap.hpp"
#include "fb_conf.hpp"
#include "graphics.hpp"

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

  // main loop

  for(int x=0;x<100;x++)
    for(int y=0;y<100;y++)
      pixel_writer->Write(x,y,{255,255,0});

  while(1){
    __asm__("hlt");
  }
}
