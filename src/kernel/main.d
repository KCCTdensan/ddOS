import asmfunc;
import lib.string;
//import error;
import memory.memory_map;
import memory.segment;
import memory.paging;
import memory.manager;
import graphics.frame_buffer;
import graphics.graphics;
import graphics.console;
import graphics.font;
import log;

alias Vec2D = Vector2D!uint;
alias uintptr = uint;

extern(C)
void KernelMain(ref const FBConf fbconf,
                ref const MemMap memmap,
                void* volume_image) {
  static LogLevel log_level = LogLevel.Info;

  // レイアウト的なの用意したい
  auto kFrameWidth = fbconf.res_horiz;
  auto kFrameHeight = fbconf.res_vert;
  auto layout_right_pane_width = 32+200+32; // 8px per pix
  auto layout_single = fbconf.res_vert < layout_right_pane_width*2+2;
  auto margin_left = kFrameWidth-layout_right_pane_width; // 2: border line

  // pixel_writer
  auto pixel_writer = PixelWriter(fbconf); // fbconfからPixelのフォーマットを察してくれる
  (&pixel_writer).FillRectangle(Vec2D(0,0),
    Vec2D(kFrameWidth,kFrameHeight),RGBColor(0,0,0));

  // kernel_console
  auto kernel_console = layout_single
    ? KConsole(&pixel_writer,
        kFrameWidth-8, kFrameHeight-8, 4, 4,
        RGBColor(0,0,0), RGBColor(0x20,0xff,0x20))
    : KConsole(&pixel_writer,
        kFrameWidth-layout_right_pane_width-8-2, kFrameHeight-8, 4, 4,
        RGBColor(0,0,0), RGBColor(0x20,0xff,0x20));
  auto kernel_sub_console = layout_single ? KConsole() : KConsole(&pixel_writer,
    layout_right_pane_width, kFrameHeight-264, margin_left+2, 264,
    RGBColor(0,0,0), RGBColor(0xff,0xff,0xff));

  // right info pane
  if(!layout_single) {
    (&pixel_writer).FillRectangle(
        Vec2D(margin_left-2,0),
        Vec2D(2,kFrameHeight),
        RGBColor(0x40,0x40,0x40));

    // QR
    bool[25][25] qrData = mixin(import("qr.txt")); // ~~/src/assets/qr.txt
    foreach(y; 0 .. 264)
      foreach(x; 0 .. 264)
        pixel_writer.write(margin_left+x,y,RGBColor(0xff,0xff,0xff));
    foreach(y; 0 .. 25)
      foreach(x; 0 .. 25)
        if(qrData[y][x])
          foreach(dy; 0 .. 8)
            foreach(dx; 0 .. 8)
              pixel_writer.write(margin_left+32+8*x+dx,32+8*y+dy,RGBColor(0,0,0));

    // info
    (&kernel_sub_console).putStr("\n      (C) 2021 KCCTdensan\n");
  }

  // とりあえず
  void printk(T ...)(string fmt, T args) {
    static if(args.length) {
      char[1024] buf = void;
      tsprintf!T(buf.ptr, cast(char*)fmt.ptr, args);
      (&kernel_console).putStr(cast(string)buf);
    } else {
      (&kernel_console).putStr(fmt);
    }
  }

  printk(" Welcome to ddOS!\n-------------------------\n");

  // セグメントの設定(最低限)とスタック領域への移動
  // GDTとやらをカーネルのスタック領域に移動するだけ
  // 要チェック
  {
    SegDesc[3] gdt;
 
    gdt[0].data=0;
    SetCodeSegment(gdt[1],SegDescType.kExecuteRead,0,0,0xfffff);
    SetDataSegment(gdt[2],SegDescType.kReadWrite,0,0,0xfffff);
    LoadGDT(gdt.sizeof-1,cast(uint)&gdt[0]);
    SetDSAll(0);
    SetCSSS(1<<3,2<<3);

    printk("GDT moved.\n");
  }

  // 階層ページング構造 をコピー
  {
    align(kPageSize4K) ulong[512] pml4_table;
    align(kPageSize4K) ulong[512] pdp_table;
    align(kPageSize4K) ulong[512][kPageDirectoryCount] page_directory;

    pml4_table[0] = cast(ulong)&pdp_table[0] | 0x003;
    foreach(int i_pdpt; 0 .. page_directory.length) {
      pdp_table[i_pdpt] = cast(ulong)&page_directory[i_pdpt] | 0x003;
      foreach(int i_pd; 0 .. 512)
        page_directory[i_pdpt][i_pd] = i_pdpt * kPageSize1G + i_pd * kPageSize2M | 0x083;
    }
    SetCR3(cast(ulong)&pml4_table[0]);

    printk("Page table moved.\n");
  }

  // メモリマップ
  printk("memory_map: 0x%x\n", cast(uint)&memmap);
  for(auto iter = cast(uintptr) memmap.buf;
      iter < cast(uintptr) memmap.buf + memmap.map_s;
      iter += memmap.desc_s) {
    auto desc = cast(MemDesc*) iter;
    //if(IsAvailable(cast(MemType)desc.type))
    //  printk("type: %d, phys: %08x - %08x, pages: %d, attr = %08x\n",
    //         desc.type,
    //         desc.physical_start,
    //         desc.physical_start + desc.number_of_pages * 4096 - 1,
    //         desc.number_of_pages,
    //         desc.attribute);
  }

  // メモリ管理
  auto memory_manager = BitmapMemoryManager();

  // ファイルシステム

  while(true) asm { hlt; }
}
