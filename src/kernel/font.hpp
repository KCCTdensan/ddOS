#pragma once

#include <cstdint>
#include "graphics.hpp"

extern int FONT_WIDTH; // declared in font.cpp
extern int FONT_HEIGHT; //

void InitValsFont(); // update int font_size[2]

void WriteFont(PixelWriter& writer,int x,int y,char c,const PixelColor& color);