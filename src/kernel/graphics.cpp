#include "graphics.hpp"

uint8_t* PixelWriter::PixelAt(int x,int y){
  return fbconf.buf+4*(fbconf.pixels_per_line*y+x);
}

void PixelWriterRGB::Write(int x,int y,const PixelColor& c){
  auto p = PixelAt(x,y);
  p[0] = c.r;
  p[1] = c.g;
  p[2] = c.b;
}

void PixelWriterBGR::Write(int x,int y,const PixelColor& c){
  auto p = PixelAt(x,y);
  p[0] = c.b;
  p[1] = c.g;
  p[2] = c.r;
}
