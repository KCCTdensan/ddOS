enum PixelFmt {
  kPixelRGB,
  kPixelBGR
}

struct FBConf {
  ubyte* buf;
  uint pixels_per_line;
  uint res_horiz;
  uint res_vert;
  PixelFmt pixel_fmt;
}