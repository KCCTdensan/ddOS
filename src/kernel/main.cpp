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
#include "driver/pci.hpp"
#include "interrupt.hpp"
#include "driver/pci.hpp" // error.hppもついてくる
#include "driver/usb/device.hpp"
#include "driver/usb/classdriver/mouse.hpp"
#include "driver/usb/xhci/xhci.hpp"
#include "driver/usb/xhci/trb.hpp"
#include "asmfunc.h"
#include "queue.hpp"

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

void SwitchEhci2Xhci(const pci::Device& xhc_dev) {
    bool intel_ehc_exist = false;
    for (int i = 0; i < pci::device_num; ++i) {
        if (pci::devices[i].class_code.Match(0x0cu, 0x03u, 0x20u) /* EHCI */ &&
            0x8086 == pci::GetVendorId(pci::devices[i])) {
            intel_ehc_exist = true;
            break;
        }
    }
    if (!intel_ehc_exist) {
        return;
    }

    uint32_t superspeed_ports = pci::ReadReg(xhc_dev, 0xdc); // USB3PRM
    pci::WriteReg(xhc_dev, 0xd8, superspeed_ports); // USB3_PSSEN
    uint32_t ehci2xhci_ports = pci::ReadReg(xhc_dev, 0xd4); // XUSB2PRM
    pci::WriteReg(xhc_dev, 0xd0, ehci2xhci_ports); // XUSB2PR
    PutLog(kLogDebug, "SwitchEhci2Xhci: SS = %02, xHCI = %02x\n",
        superspeed_ports, ehci2xhci_ports);
}

usb::xhci::Controller* xhc;
struct Message {
  enum Type{
    kInterruptXHCI,
  } type;
};
ArrayQueue<Message>* main_queue;
__attribute__((interrupt))
void IntHandlerXHCI(InterruptFrame* frame) {
  main_queue->Push(Message{Message::kInterruptXHCI});
  NotifyEndOfInterrupt();
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
  const uint16_t cs = GetCS();
  SetIDTEntry(idt[InterruptVector::kXHCI], MakeIDTAttr(DescriptorType::kInterruptGate, 0),
              reinterpret_cast<uint64_t>(IntHandlerXHCI), cs);
  LoadIDT(sizeof(idt) - 1, reinterpret_cast<uintptr_t>(&idt[0]));

  // MSI割り込みenable
  const uint8_t bsp_local_apic_id = *reinterpret_cast<const uint32_t*>(0xfee00020) >> 24;
  pci::ConfigureMSIFixedDestination(
          *xhc_dev, bsp_local_apic_id, pci::MSITriggerMode::kLevel, pci::MSIDeliveryMode::kFixed, InterruptVector::kXHCI, 0);

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

//  // do port setting by searching usb port (mouse)
//  usb::HIDMouseDriver::default_observer = MouseObserver;
//  for(int i=0;i<=xhc.MaxPorts();i++){
//    auto port = xhc.PortAt(i);
//    PutLog(kLogDebug, "Port %d: IsConnected=%d\n", i, port.IsConnected());
//    if(port.IsConnected()){
//      if(auto err = ConfigurePort(xhc, port)){
//        PutLog(kLogError, "failed to configure port: %s at %s:%d\n", err.Name(), err.File(), err.Line());
//        continue;œ
//      }
//    }
//  }

//  while(1){
//    if(auto err = ProcessEvent(xhc)){
//      PutLog(kLogError, "Error while ProcessEvent: %s at %s:%d\n", err.Name(), err.File(), err.Line());
//    }
//  }

  while(true){
    __asm__("cli");
    if(main_queue->Count()){
      __asm__("sti\n\thlt");
      continue;
    }
    Message msg = main_queue->Front();
    main_queue->pop();
    __asm__("sti");

    switch(msg.type){
      case Message::kInterruptXHCI:
        while(xhc.PrimaryEventRing()->HasFront()){
          if(auto err=ProcessEvent(xhc)){
            PutLog(kLogError, "Error while ProcessEvent: %s at %s:%d\n", err.Name(), err.File(), err.Line());
          }
        }
        break;
      default:
        PutLog(kLogError, "Unknown message type: %d\n", msg.type);
    }
  }






  // main loop

  while(1){
    __asm__("hlt");
  }
}
