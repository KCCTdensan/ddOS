#pragma once

#include "graphics.hpp"
#include "font.hpp"

extern const unsigned int KCONSOLE_BUF_MAX_COL;
extern const unsigned int KCONSOLE_BUF_MAX_ROW;
extern const PixelColor KCONSOLE_BG;

class kConsole {
public:
  kConsole(PixelWriter& writer_,
           unsigned int horiz_,
           unsigned int vert_,
           unsigned int x_,
           unsigned int y_,
           const PixelColor& bg_color_,
           const PixelColor& text_color_);
  ~kConsole() = default;
  void PutStr(const char*);
private:
  PixelWriter& pixel_writer;
  const PixelColor& bg_color, text_color;
  unsigned int col, row, buf_x, buf_y, start_x, start_y, cursor_col, cursor_row;
  char* text_buf;
  void PutNL(); // NewLine
};
