#pragma once

#include <stdint.h>

enum PixelFmt{
  kPixelRGB,
  kPixelBGR
};

struct FBConf{
  uint8_t* buf;
  uint32_t pixels_per_line;
  uint32_t res_horiz;
  uint32_t res_vert;
  enum PixelFmt pixel_fmt;
};
