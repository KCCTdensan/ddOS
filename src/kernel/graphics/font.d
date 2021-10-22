module ddos.font;

import graphics.graphics;

extern const ubyte _binary_fontascii_bin_start;
extern const ubyte _binary_fontascii_bin_end;
extern const ubyte _binary_fontascii_bin_size;

int FONT_WIDTH=0; // also used in font.hpp
int FONT_HEIGHT=0; //

// ASCII

struct FontAscii_font{
  ubyte width; // up to 8
  ubyte height; // up to 16
  ubyte[256][16] buf; // 16Byte per font
}

void FontAscii_writer(ref PixelWriter writer,
                      int x,int y,uint c,
                      ref const PixelColor color){
  const FontAscii_font* font_ascii=
    cast(const FontAscii_font*)(&_binary_fontascii_bin_start);

  if(c >= 256)return; // 文字を化かす
  for(ubyte dy=0;dy<font_ascii.height;++dy)
    for(ubyte dx=0;dx<font_ascii.width;++dx)
      if(font_ascii.buf[c][dy]&(0x80u>>dx))
        writer.Write(x+dx,y+dy,color);
}

// 日本語のやつここらへんに入れたい

// 共通

extern (C++)
void InitFont(){
  const FontAscii_font* font_ascii=
    cast(const FontAscii_font*)(&_binary_fontascii_bin_start);
  FONT_WIDTH=font_ascii.width;
  FONT_HEIGHT=font_ascii.height;
}

extern (C++)
void WriteFont(ref PixelWriter writer,
               int x,int y,char c,
               ref const PixelColor color){
  FontAscii_writer(writer,x,y,cast(uint)c,color);
}
