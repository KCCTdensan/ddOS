import std.algorithm : min;
import core.stdc.string : memcpy;

import display.graphics;
import display.font;

alias Vec2D = display.graphics.Vector2D!uint;

const uint KConsole_buf_max_col = 162; // 黄金比(適当)
const uint KConsole_buf_max_row = 100;
const RGBColor KConsole_bgc = RGBColor(0,0,0); // RGBColor 余"白"(黒だけど)

struct KConsole {
  this(PixelWriter* writer_,
       uint horiz_, uint vert_,
       uint x_, uint y_,
       const RGBColor bg_color_,
       const RGBColor text_color_) {
    Font_width = 8; // font.dから取得したいけど
    Font_height = 16;

    pixel_writer = writer_;
    bg_color = bg_color_;
    text_color = text_color_;
    cursor_col = cursor_row = 0;
    //text_buf = {{}}; // Dなので初期化済み，ありがたい
    col = min(KConsole_buf_max_col, horiz_ / Font_width); // 0除算しがち
    row = min(KConsole_buf_max_row, vert_ / Font_height);
    buf_x = Font_width * col;
    buf_y = Font_height * row;
    start_x = x_ + (horiz_ - buf_x) / 2;
    start_y = y_ + (vert_ - buf_y) / 2;

    FillRectangle(pixel_writer, Vec2D(x_,y_), Vec2D(horiz_,vert_), KConsole_bgc);
    FillRectangle(pixel_writer, Vec2D(start_x,start_y), Vec2D(buf_x,buf_y), bg_color);
  }
  void putStr(string s) {
    int x = start_x + Font_width * cursor_col,
        y = start_y + Font_height * cursor_row;
    foreach(c; s)
      switch(c) {
        case '\n':
          putNL();
          x = 0;
          y = start_y + Font_height * cursor_row;
          break;
        default:
          WriteFont(pixel_writer, x, y, c, text_color);
          text_buf[cursor_row][cursor_col] = c;
          if(cursor_col < col-1) {
            ++cursor_col;
            x += Font_width;
          } else {
            putNL();
            x = 0;
            y = start_y + Font_height * cursor_row;
          }
      }
  }

private:
  void putNL() { // NewLine
    cursor_col = 0;
    if(cursor_row < row-1)
      ++cursor_row;
    else {
      FillRectangle(pixel_writer, Vec2D(start_x,start_y), Vec2D(buf_x,buf_y), bg_color);
      foreach(cursor_row; 0 .. row-1) {
        memcpy(&text_buf[cursor_row], &text_buf[cursor_row+1], col);
        uint x = 0;
        uint y = start_y + Font_height * cursor_row;
        foreach(c; text_buf[cursor_row]) {
          WriteFont(pixel_writer, x, y, c, text_color);
          x += Font_width;
        }
      }
    }
  }

  PixelWriter* pixel_writer;
  const RGBColor bg_color, text_color;
  uint col, row, buf_x, buf_y, start_x, start_y, cursor_col, cursor_row;
  ubyte Font_width, Font_height;
  char[KConsole_buf_max_row][KConsole_buf_max_col+1] text_buf;
}

// log

//enum LogLevel {
//  kLogError = 3,
//  kLogWarn  = 4,
//  kLogInfo  = 6, // default
//  kLogDebug = 7,
//}

//LogLevel log_level = LogLevel.kLogInfo;

//KConsole kernel_console;

//void SetLogLevel(LogLevel lev) {
//  log_level=lev;
//}

//static if(true) {
//  extern(C++)
//  alias PutLog = PutLogScreen;
//} else {
//}

//int PutLogScreen(T ...)(LogLevel lev, string fmt, T args) {

//  if(lev>log_level) return 0;
//  int res;
//  ubyte[1024] buf;

//  res = vsprintf(buf,fmt,args);

//  kernel_console.PutStr(buf);
//  return res;
//}