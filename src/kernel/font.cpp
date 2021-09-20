#include "font.hpp"

extern const uint8_t _binary_fontascii_bin_start;
extern const uint8_t _binary_fontascii_bin_end;
extern const uint8_t _binary_fontascii_bin_size;

int FONT_WIDTH=0; // also used in font.hpp
int FONT_HEIGHT=0; //

// ASCII

struct FontAscii_font{
  uint8_t width; // up to 8
  uint8_t height; // up to 16
  uint8_t buf[256][16]; // 16Byte per font
};

void FontAscii_writer(PixelWriter& writer,
                      int x,int y,unsigned int c,
                      const PixelColor& color){
  const FontAscii_font* font_ascii=
    reinterpret_cast<const FontAscii_font*>(&_binary_fontascii_bin_start);

  if(c >= 256)return; // 文字を化かす
  for(uint8_t dy=0;dy<font_ascii->height;dy++)
    for(uint8_t dx=0;dx<font_ascii->width;dx++)
      if(font_ascii->buf[c][dy]&(0x80u>>dx))
        writer.Write(x+dx,y+dy,color);
}

// 日本語のやつここらへんに入れたい

// 共通

void InitValsFont(){
  const FontAscii_font* font_ascii=
    reinterpret_cast<const FontAscii_font*>(&_binary_fontascii_bin_start);
  FONT_WIDTH=font_ascii->width;
  FONT_HEIGHT=font_ascii->height;
}

void WriteFont(PixelWriter& writer,
               int x,int y,char c,
               const PixelColor& color){
  void FontAscii_writer(PixelWriter&,int,int,unsigned int,const PixelColor&);

  FontAscii_writer(writer,x,y,static_cast<unsigned int>(c),color);
}
