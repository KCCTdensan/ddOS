import std.conv : emplace;

import fb_conf;
import error;
import display.graphics;
import display.console;

// cppfunc.cpp
//int printk(T...)(string fmt, ...);
//

KConsole kernel_console; // 実質ポインタ
ubyte[__traits(classInstanceSize, KConsole)] kernel_console_buf = void;

// // //
//ubyte[__traits(classInstanceSize, YourClass)] buffer;
//YourClass obj = emplace!YourClass(buffer[], ctor args...);
// // //

extern(C)
void KernelMain(ref const FBConf fbconf) {

  // pixel_writer
  PixelWriter pixel_writer;
  ubyte[PixelWriterRGB.sizeof] pixel_writer_buf = void;
  final switch(fbconf.pixel_fmt) {
    case PixelFmt.kPixelRGB:
      pixel_writer = emplace!PixelWriterRGB(pixel_writer_buf, fbconf);
      break;
    case PixelFmt.kPixelBGR:
      pixel_writer = emplace!PixelWriterBGR(pixel_writer_buf, fbconf);
      break;
  }

  // kernel_console
  //InitFont();
  kernel_console = emplace!KConsole(
    kernel_console_buf, &pixel_writer,
    fbconf.res_horiz-8, fbconf.res_vert-8,
    4, 4, RGBColor(0,0,0), RGBColor(0x20,0xff,0x20));

  //printk("Kernel console initialized.\n");

  while(true) asm { hlt; }
}
