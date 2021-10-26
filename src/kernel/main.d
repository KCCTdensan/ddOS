import fb_conf;
//import error;
import display.graphics;
import display.font;
import display.console;

alias Vec2D = display.graphics.Vector2D!uint;

// cppfunc.cpp
//int printk(T...)(string fmt, ...);
//

extern(C)
void KernelMain(ref const FBConf fbconf) {

  // pixel_writer
  auto pixel_writer = PixelWriter(fbconf); // fbconfからPixelのフォーマットを察してくれる

  // kernel_console
  auto kernel_console = KConsole(&pixel_writer,
    fbconf.res_horiz-8, fbconf.res_vert-8, 4, 4,
    RGBColor(0,0,0), RGBColor(0x20,0xff,0x20));

  kernel_console.putStr("ABCDEF");

  //printk("Kernel console initialized.\n");

  while(true) asm { hlt; }
}
