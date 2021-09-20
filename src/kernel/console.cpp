#include <cstring>

#include "console.hpp"

template<typename T>
inline const T& min(const T& a,const T& b){
  return a<b?a:b;
}

Console::Console(PixelWriter& writer_,
                 unsigned int horiz_,unsigned int vert_,
                 unsigned int x_,unsigned int y_,
                 const PixelColor& bg_color_,
                 const PixelColor& text_color_) :
    pixel_writer(writer_),
    bg_color(bg_color_),
    text_color(text_color_),
    cursor_col(0),
    cursor_row(0),
    text_buf(){
  col=min(CONSOLE_BUF_MAX_COL,(unsigned int)horiz_/FONT_WIDTH);
  row=min(CONSOLE_BUF_MAX_ROW,(unsigned int)vert_/FONT_HEIGHT);
  buf_x=FONT_WIDTH*col;
  buf_y=FONT_HEIGHT*row;
  start_x=x_+(horiz_-buf_x)/2;
  start_y=y_+(vert_-buf_y)/2;

  FillRectangle(pixel_writer,
                {x_,y_},{horiz_,vert_},
                CONSOLE_BG);
  FillRectangle(pixel_writer,
                {start_x,start_y},{buf_x,buf_y},
                bg_color);
}

void Console::PutStr(const char* s){
  int x=start_x+FONT_WIDTH*cursor_col,
      y=start_y+FONT_HEIGHT*cursor_row;
  for(;*s;s++)
    switch(*s){
      case '\n':
        PutNL();
        x=0;
        y=start_y+FONT_HEIGHT*cursor_row;
        break;
      default:
        text_buf[cursor_row][cursor_col]=*s;
        WriteFont(pixel_writer,x,y,*s,text_color);
        if(cursor_col<col-1){
          cursor_col++;
          x+=FONT_WIDTH;
        }else{
          PutNL();
          x=0;
          y=start_y+FONT_HEIGHT*cursor_row;
        }
    }
}

void Console::PutNL(){
  cursor_col=0;
  if(cursor_row<row-1)
    cursor_row++;
  else{
    FillRectangle(pixel_writer,
                  {start_x,start_y},{buf_x,buf_y},
                  bg_color);
    unsigned int x,y;const char* s;
    for(cursor_row=0;cursor_row<row-1;cursor_row++){
      memcpy(text_buf[cursor_row],text_buf[cursor_row+1],col);
      x=0,y=start_y+FONT_HEIGHT*cursor_row;
      for(s=text_buf[cursor_row];*s;s++,x+=FONT_WIDTH)
        WriteFont(pixel_writer,x,y,*s,text_color);
    }
  }
}
