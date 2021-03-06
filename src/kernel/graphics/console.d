import std.algorithm : min;

import lib.string;
import graphics.graphics;
import graphics.font;

alias Vec2D = Vector2D!uint;

const uint KConsole_buf_max_col = 162; // 黄金比(適当)
const uint KConsole_buf_max_row = 100;
const RGBColor KConsole_bgc = RGBColor(0,0,0); // RGBColor 余"白"(黒だけど)

struct KConsole {
  this(PixelWriter* writer_,
       uint horiz_, uint vert_,
       uint x_, uint y_,
       const RGBColor bg_color_,
       const RGBColor text_color_) {
    FontSize fontsize = GetFontSize();

    cursor_col = cursor_row = row_index = 0;
    pixel_writer = writer_;
    bg_color = bg_color_;
    text_color = text_color_;
    font_width = fontsize.w;
    font_height = fontsize.h;
    col = min(KConsole_buf_max_col, horiz_ / font_width);
    row = min(KConsole_buf_max_row, vert_ / font_height);
    buf_x = font_width * col;
    buf_y = font_height * row;
    start_x = x_ + (horiz_ - buf_x) / 2;
    start_y = y_ + (vert_ - buf_y) / 2;
    // text_buf; // Dなので初期化済み，ありがたい

    FillRectangle(pixel_writer, Vec2D(x_,y_), Vec2D(horiz_,vert_), KConsole_bgc);
    FillRectangle(pixel_writer, Vec2D(start_x,start_y), Vec2D(buf_x,buf_y), bg_color);
  }
  void putStr(string s) {
    x = start_x + font_width * cursor_col,
    y = start_y + font_height * cursor_row;
    eachchar: foreach(c; s)
      switch(c) {
        case '\0':
          text_buf[cursor_row][cursor_col] = '\0';
          break eachchar;
        case '\n':
          text_buf[cursor_row][cursor_col] = '\0';
          putNL();
          x = start_x;
          y = start_y + font_height * cursor_row;
          break;
        default:
          WriteFont(pixel_writer, x, y, c, text_color);
          text_buf[cursor_row][cursor_col] = c;
          if(cursor_col < col-1) {
            ++cursor_col;
            x += font_width;
          } else {
            text_buf[cursor_row][cursor_col+1] = '\0';
            putNL();
            x = start_x;
            y = start_y + font_height * cursor_row;
          }
      }
    //text_buf[cursor_row][cursor_col] = '\0';
  }

private:
  void putNL() { // NewLine
    if(cursor_row < row-1) {
      ++cursor_row;
    } else {
      FillRectangle(pixel_writer, Vec2D(start_x,start_y), Vec2D(buf_x,buf_y), bg_color);
      foreach(rowi; 0 .. row-1) {
        memcpy(text_buf[rowi].ptr, text_buf[rowi+1].ptr, col+1);
        x = start_x,
        y = start_y + font_height * rowi;
        foreach(c; text_buf[rowi]) {
          if(!c) break;
          WriteFont(pixel_writer, x, y, c, text_color);
          x += font_width;
        }
      }
    }
    cursor_col = 0;
  }

  uint cursor_col, cursor_row, x, y, row_index;
  const PixelWriter* pixel_writer;
  const RGBColor bg_color, text_color;
  const ubyte font_width, font_height;
  const uint col, row, buf_x, buf_y, start_x, start_y;
  char[KConsole_buf_max_col+1][KConsole_buf_max_row] text_buf;
}
