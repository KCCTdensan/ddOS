import fb_conf;
//import error;
import display.graphics;
import display.console;
import log;

alias Vec2D = display.graphics.Vector2D!uint;

extern(C)
void KernelMain(ref const FBConf fbconf) {
  // レイアウト的なの用意したい
  auto layout_single = fbconf.res_vert < 512;
  auto layout_right_pane_width = 256;

  // pixel_writer
  auto pixel_writer = PixelWriter(fbconf); // fbconfからPixelのフォーマットを察してくれる
  (&pixel_writer).FillRectangle(Vec2D(0,0),
    Vec2D(fbconf.res_horiz,fbconf.res_vert),RGBColor(0,0,0));

  // kernel_console
  auto kernel_console = layout_single
    ? KConsole(&pixel_writer,
        fbconf.res_horiz-8, fbconf.res_vert-8, 4, 4,
        RGBColor(0,0,0), RGBColor(0x20,0xff,0x20))
    : KConsole(&pixel_writer,
        fbconf.res_horiz-layout_right_pane_width-8, fbconf.res_vert-8, 4, 4,
        RGBColor(0,0,0), RGBColor(0xff,0xff,0xff));

  // right info pane
  if(!layout_single) {
    auto margin_left = fbconf.res_horiz-layout_right_pane_width-8;
    (&pixel_writer).FillRectangle(
        Vec2D(margin_left,0),
        Vec2D(2,fbconf.res_vert),
        RGBColor(0x40,0x40,0x40));
  }

  // showing log
  extern(C++)
  __gshared LogLevel log_level = LogLevel.Info;

  (&kernel_console).putStr("Welcome to ddOS!\n");

  //alias printk = kernel_console.putLog();

  //(&kernel_console).printk("Kernel console initialized.%d\n",2);

  while(true) asm { hlt; }
}
