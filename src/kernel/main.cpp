#include <cstdint>
#include <cstddef>
#include <cstdio>

#include "elf.hpp"
#include "memmap.hpp"
#include "fb_conf.hpp"
#include "graphics.hpp"
#include "font.hpp"
#include "console.hpp"
#include "log.hpp"
#include "driver/pci.hpp" // error.hppもついてくる
#include "driver/usb/memory.hpp"
#include "driver/usb/xhci/device.hpp"
//#include "usb/xhci/xhci.hpp"
//#include "usb/xhci/trb.hpp"

kConsole* kernel_console;
char kernel_console_buf[sizeof(kConsole)];

// 配置newはmikan側のincludeで定義されてた

int printk(const char* fmt,...){
  va_list ap;
  int res;
  char s[1024];

  va_start(ap,fmt);
  res=vsprintf(s,fmt,ap);
  va_end(ap);

  kernel_console->PutStr(s);
  return res;
}

extern "C" void KernelMain(const FBConf& fbconf){
  // InitFont();

  // pixel_writer
  PixelWriter* pixel_writer;
  char pixel_writer_buf[sizeof(PixelWriterRGB)];
  switch(fbconf.pixel_fmt){
    case kPixelRGB:
      pixel_writer = new(pixel_writer_buf) PixelWriterRGB(fbconf);
      break;
    case kPixelBGR:
      pixel_writer = new(pixel_writer_buf) PixelWriterBGR(fbconf);
      break;
  }

  // kernel_console
  InitFont();
  kernel_console = new(kernel_console_buf) kConsole(
      *pixel_writer,
      fbconf.res_horiz-8,
      fbconf.res_vert-8,
      4,4,{0,0,0},{0x20,0xff,0x20});
  PutLog(kLogInfo,"Kernel console initialized.\n");

  // pci
  PutLog(kLogInfo,"pci::ScanAllBus ...");
  auto pci_scanall_err=pci::ScanAllBus();
  PutLog(kLogInfo," %s\n",pci_scanall_err.Name());
  for(int i=0;i<pci::device_num;i++){
    const auto& dev=pci::devices[i];
    auto vendor_id=pci::GetVendorId(dev.bus_id,dev.dev_id,dev.func_id);
    auto class_code=pci::GetClassCode(dev.bus_id,dev.dev_id,dev.func_id);
    PutLog(kLogInfo,"%d.%d.%d: vend %04x, class %8x, head %2x\n",
           dev.bus_id,dev.dev_id,dev.func_id,
           vendor_id,class_code,dev.header_type);
  }

  // find xHC
  pci::Device* xhc_dev = nullptr;
  for(int i=0;i<pci::device_num;i++) {
      if (pci::devices[i].class_code.Match(0x0cu, 0x03u, 0x30u)) {
          xhc_dev = &pci::devices[i];
          if (0x8086 == pci::GetVendorId(*xhc_dev)) {
              break;
          }
      }
  }
  if(xhc_dev){
      PutLog(kLogInfo, "xHC has been found: %d.%d.%d\n", xhc_dev->bus_id, xhc_dev->dev_id, xhc_dev->func_id);
  }

  // read BAR0
  const WithError<uint64_t> xhc_bar = pci::ReadBar(*xhc_dev, 0);
  PutLog(kLogDebug, "ReadBar: %s\n", xhc_bar.error.Name());
  const uint64_t xhc_mmio_base = xhc_bar.data & ~static_cast<uint64_t>(0xf);
  PutLog(kLogDebug, "xHC mmio_base = %08lx\n", xhc_mmio_base);

  // initialize xHC and start up
  usb::xhci::Controller xhc{xhc_mmio_base};
  if(0x8086 == pci::GetVendorId(*xhc_dev)){
      SwitchEhci2Xhci(*xhc_dev);
  }
  {
    auto err = xhc.Initialize();
    PutLog(kLogDebug, "xhc.Initialize: %s\n", err.Name());
  }
  PutLog(kLogInfo, "xHC starting\n");
  xhc.Run();



  // main loop

  while(1){
    __asm__("hlt");
  }
}
