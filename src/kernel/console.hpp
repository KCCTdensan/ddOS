#pragma once

#include "graphics.hpp"
#include "font.hpp"

static const unsigned int CONSOLE_BUF_MAX_COL=162; // 黄金比(適当)
static const unsigned int CONSOLE_BUF_MAX_ROW=100;
static const PixelColor CONSOLE_BG={0,0,0}; // PixelColor 余"白"(黒だけど)

class Console{
public:
  Console(PixelWriter& writer_,
          unsigned int horiz_,
          unsigned int vert_,
          unsigned int x_,
          unsigned int y_,
          const PixelColor& bg_color_,
          const PixelColor& text_color_);
  ~Console()=default;
  void PutStr(const char*);
private:
  PixelWriter& pixel_writer;
  const PixelColor& bg_color,text_color;
  unsigned int col,row,buf_x,buf_y,start_x,start_y,cursor_col,cursor_row;
  char text_buf[CONSOLE_BUF_MAX_ROW][CONSOLE_BUF_MAX_COL+1];
  void PutNL(); // NewLine
};
