import std.algorithm; // min使うため

import graphics = display.graphics;
alias Vec2D = graphics.Vector2D;
alias RGBColor = graphics.RGBColor;

static const uint KCONSOLE_BUF_MAX_COL = 162; // 黄金比(適当)
static const uint KCONSOLE_BUF_MAX_ROW = 100;
static const RGBColor KCONSOLE_BG = RGBColor(0,0,0); // RGBColor 余"白"(黒だけど)

extern(C++)
class KConsole {
public:
  this(const graphics.PixelWriter* writer_,
       uint horiz_,uint vert_,
       uint x_, uint y_,
       const RGBColor bg_color_,
       const RGBColor text_color_){
    pixel_writer = *writer_;
    bg_color = bg_color_;
    text_color = text_color_;
    cursor_col = cursor_low = 0;
    //text_buf = {{}}; // Dなので初期化済み
    col = min(KCONSOLE_BUF_MAX_COL, cast(uint)horiz_ / FONT_WIDTH);
    row = min(KCONSOLE_BUF_MAX_ROW, cast(uint)vert_ / FONT_HEIGHT);
    buf_x = FONT_WIDTH * col;
    buf_y = FONT_HEIGHT * row;
    start_x = x_ + (horiz_ - buf_x) / 2;
    start_y = y_ + (vert_ - buf_y) / 2;

    graphics.FillRectangle(pixel_writer, Vec2D(x_,y_), Vec2D(horiz_,vert_), KCONSOLE_BG);
    graphics.FillRectangle(pixel_writer, Vec2D(start_x,start_y), Vec2D(buf_x,buf_y), bg_color);
  }
  void PutStr(const char* s){
    int x = start_x + FONT_WIDTH * cursor_col,
        y = start_y + FONT_HEIGHT * cursor_row;
    for(;*s;s++)
      switch(*s) {
      case '\n':
        PutNL();
        x = 0;
        y = start_y + FONT_HEIGHT * cursor_row;
        break;
      default:
        text_buf[cursor_row][cursor_col]=*s;
        WriteFont(pixel_writer,x,y,*s,text_color);
        if(cursor_col < col-1) {
          ++cursor_col;
          x += FONT_WIDTH;
        } else {
          PutNL();
          x = 0;
          y = start_y + FONT_HEIGHT * cursor_row;
        }
      }
  }
private:
  void PutNL(){ // NewLine
    cursor_col=0;
    if(cursor_row<row-1)
      cursor_row++;
    else {
      graphics.FillRectangle(pixel_writer, Vec2D(start_x,start_y), Vec2D(buf_x,buf_y), bg_color);
      uint x,y;
      const char* s;
      foreach(cursor_row; 0 .. row-1) {
        memcpy(text_buf[cursor_row], text_buf[cursor_row+1], col);
        x = 0;
        y = start_y + FONT_HEIGHT * cursor_row;
        for(s = text_buf[cursor_row]; *s; ++s, x+=FONT_WIDTH)
          WriteFont(pixel_writer,x,y,*s,text_color);
      }
    }
  }

  const graphics.PixelWriter pixel_writer;
  const RGBColor bg_color, text_color;
  uint col, row, buf_x, buf_y, start_x, start_y, cursor_col, cursor_row;
  char[KCONSOLE_BUF_MAX_ROW][KCONSOLE_BUF_MAX_COL+1] text_buf;
}

// log

enum LogLevel {
  kLogError = 3,
  kLogWarn  = 4,
  kLogInfo  = 6, // default
  kLogDebug = 7,
}

LogLevel log_level = LogLevel.kLogInfo;

KConsole kernel_console;

void SetLogLevel(LogLevel lev) {
  log_level=lev;
}

static if(true) {
  extern(C++)
  alias PutLog = PutLogScreen;
} else {
}

int PutLogScreen(T ...)(LogLevel lev, string fmt, T args) {

  if(lev>log_level) return 0;
  int res;
  ubyte[1024] buf;

  res = vsprintf(buf,fmt,args);

  kernel_console.PutStr(buf);
  return res;
}
