import graphics.graphics;

private {
  extern extern(C) {
    // ASCII
    const FontBuf _binary_display_fontascii_bin_start; // aliased as font_ascii
    //const ubyte _binary_display_fontascii_bin_start;
    //const ubyte _binary_display_fontascii_bin_end;
    //const ubyte _binary_display_fontascii_bin_size;
  }

  alias font_ascii = _binary_display_fontascii_bin_start;

  struct FontBuf {
    ubyte width; // up to 8
    ubyte height; // up to 16
    ubyte[16][256] buf; // 16Byte per font (ascii only)
  }

  // WriteFont()の中に入れるか迷う
  void write(const FontBuf* fonts,
             const PixelWriter* writer,
             int x,int y, char c,
             const RGBColor color) {
    foreach(dy; 0 .. fonts.height)
      foreach(dx; 0 .. fonts.width)
        if(fonts.buf[c][dy] & (0x80u >> dx))
          writer.write(x+dx, y+dy, color);
  }
}

struct FontSize { ubyte w,h; }
FontSize GetFontSize() {
  FontSize fsize;
  fsize.w = font_ascii.width;
  fsize.h = font_ascii.height;
  return fsize;
}

void WriteFont(const PixelWriter* writer,
               int x, int y, char c,
               const RGBColor color) {
  if(c < 256)
    (&font_ascii).write(writer, x, y, c, color);
  else // ToDo: いい感じに文字を化かす
    foreach(dy; 0 .. font_ascii.height)
      foreach(dx; 0 .. font_ascii.width)
          writer.write(x+dx, y+dy, color);
}
