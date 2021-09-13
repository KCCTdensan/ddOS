#pragma once

#include <cstdint>
#include "graphics.hpp"

struct Font{
  uint8_t width;
  uint8_t height;
  uint8_t buf[16*256];
}

extern const uint8_t _binary_fontascii_bin_start;
extern const uint8_t _binary_fontascii_bin_end;
extern const uint8_t _binary_fontascii_bin_size;

// void WriteAscii(PixelWriter& writer, int x, int y, char c, const PixelColor& color);
