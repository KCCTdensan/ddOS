import fb_conf;
import memmap;
//import error;
import display.graphics;
import display.console;
import log;

alias Vec2D = display.graphics.Vector2D!uint;
alias uintptr = uint;

align(16) extern(C)
__gshared ubyte[1024 * 1024] kernel_main_stack;

extern(C)
void KernelMainNewStack(ref const FBConf fbconf,
                        ref const MemMap memmap) {
  // レイアウト的なの用意したい
  auto kFrameWidth = fbconf.res_horiz;
  auto kFrameHeight = fbconf.res_vert;
  auto layout_single = kFrameWidth < 512;
  auto layout_right_pane_width = 256;

  // pixel_writer
  auto pixel_writer = PixelWriter(fbconf); // fbconfからPixelのフォーマットを察してくれる
  FillRectangle(&pixel_writer,Vec2D(0,0),
    Vec2D(kFrameWidth,kFrameHeight),RGBColor(0,0,0));

  // kernel_console
  auto kernel_console = layout_single
    ? KConsole(&pixel_writer,
        kFrameWidth-8, kFrameHeight-8, 4, 4,
        RGBColor(0,0,0), RGBColor(0x20,0xff,0x20))
    : KConsole(&pixel_writer,
        kFrameWidth-layout_right_pane_width-8, kFrameHeight-8, 4, 4,
        RGBColor(0,0,0), RGBColor(0xff,0xff,0xff));

  // temp 要置き換え
  void printk(string s) {
    kernel_console.putStr(s);
  }
  //

  // right info pane
  if(!layout_single) {
    auto margin_left = kFrameWidth-layout_right_pane_width-8;
    FillRectangle(&pixel_writer,
        Vec2D(margin_left,0),
        Vec2D(2,kFrameHeight),
        RGBColor(0x40,0x40,0x40));

    // QR (27+200+27 x 27+200+27)
  }

  // showing log
  extern(C++)
  __gshared LogLevel log_level = LogLevel.Info;

  printk("Welcome to ddOS!\n");

  // メモリ
  for(auto iter = cast(uintptr) memmap.buf;
      iter < cast(uintptr) memmap.buf + memmap.map_s;
      iter += memmap.desc_s) {
    auto desc = cast(MemDesc*) iter;
    //a
  }

  while(true) asm { hlt; }
}
