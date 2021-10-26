import display.graphics;

//extern extern(C) __gshared FontAscii_font* font_ascii;

// ASCII
private {
  extern extern(C) {
    const char _binary_display_fontascii_bin_start;
    const char _binary_display_fontascii_binn_end;
    const char _binary_display_fontascii_bin_size;
  }

  struct FontAscii_font {
    ubyte width; // up to 8
    ubyte height; // up to 16
    ubyte[256][16] buf; // 16Byte per font
  }

  void FontAscii_writer(const PixelWriter* writer,
                        int x,int y, uint/*わざと*/ c,
                        const RGBColor color) {
    auto font_ascii = cast(FontAscii_font*) &_binary_display_fontascii_bin_start;

    foreach(dy; 0 .. font_ascii.height)
      foreach(dx; 0 .. font_ascii.width)
        if(font_ascii.buf[c][dy]&(0x80>>dx)) // ここが怪レい
          writer.write(x+dx, y+dy, color);
  }
}

// 日本語のやつここらへんに入れたい

// 共通

struct FontInfo {
  this(ubyte w,ubyte h) { this.width=w; this.height=h; }
  const ubyte width,height;
}
FontInfo GetFontInfo() {
  auto font_ascii = cast(FontAscii_font*) &_binary_display_fontascii_bin_start;
  return FontInfo(font_ascii.width, font_ascii.height);
}

void WriteFont(const PixelWriter* writer,
               int x, int y, char c,
               const RGBColor color) {
  auto font_ascii = cast(FontAscii_font*) &_binary_display_fontascii_bin_start;

  if(c < 256)
    FontAscii_writer(writer, x, y, cast(uint)c, color);
  else // ToDo: いい感じに文字を化かす
    foreach(dy; 0 .. font_ascii.height)
      foreach(dx; 0 .. font_ascii.width)
          writer.write(x+dx, y+dy, color);
}
