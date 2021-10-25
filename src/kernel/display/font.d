import display.graphics;

extern(C) {
  const ubyte _binary_fontascii_bin_start;
  const ubyte _binary_fontascii_bin_end;
  const ubyte _binary_fontascii_bin_size;
}

// ASCII
private {

  FontAscii_font* font_ascii = cast(FontAscii_font*) &_binary_fontascii_bin_start;

  struct FontAscii_font{
    ubyte width; // up to 8
    ubyte height; // up to 16
    ubyte[256][16] buf; // 16Byte per font
  }

  void FontAscii_writer(const PixelWriter* writer,
                        int x,int y, uint/*わざと*/ c,
                        const RGBColor color){
    if(c >= 256) // ToDo: いい感じに文字を化かす
      foreach(dy; 0 .. font_ascii.height)
        foreach(dx; 0 .. font_ascii.width)
          writer.write(x+dx, y+dy, color);
    else
      foreach(dy; 0 .. font_ascii.height)
        foreach(dx; 0 .. font_ascii.width)
          if(font_ascii.buf[c][dy]&(0x80u>>dx))
            writer.write(x+dx, y+dy, color);
  }
}

// 日本語のやつここらへんに入れたい

// 共通

void LoadFont() { // メモリに読み込む
  //font_ascii = cast(FontAscii_font*) &_binary_fontascii_bin_start;
  //Font_width = font_ascii.width;
  //Font_height = font_ascii.height;
}

void WriteFont(const PixelWriter* writer,
               int x, int y, char c,
               const RGBColor color) {
  FontAscii_writer(writer, x, y, cast(uint)c, color);
}
