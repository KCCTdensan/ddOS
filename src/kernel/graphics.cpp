#include "graphics.hpp"

uint8_t* PixelWriter::PixelAt(unsigned int x,unsigned int y){
  return fbconf.buf+4*(fbconf.pixels_per_line*y+x);
}

void PixelWriterRGB::Write(unsigned int x,
                           unsigned int y,
                           const PixelColor& c){
  auto p = PixelAt(x,y);
  p[0] = c.r;
  p[1] = c.g;
  p[2] = c.b;
}

void PixelWriterBGR::Write(unsigned int x,unsigned int y,
                           const PixelColor& c){
  auto p = PixelAt(x,y);
  p[0] = c.b;
  p[1] = c.g;
  p[2] = c.r;
}

void FillRectangle(PixelWriter& writer,const Vector2D<unsigned int>& start,
                   const Vector2D<unsigned int>& size,const PixelColor& c){
  for(int dy=0;dy<size.y;dy++)
    for(int dx=0;dx<size.x;dx++)
      writer.Write(start.x+dx,start.y+dy,c);
}
