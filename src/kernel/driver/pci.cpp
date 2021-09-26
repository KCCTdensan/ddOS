#include "pci.hpp"
#include "asmfunc.h"

namespace {
  using namespace pci;

  uint32_t MakeConfigAddrVal(uint8_t bus_id,
                             uint8_t dev_id,
                             uint8_t func_id,
                             uint8_t reg_offset){
    auto shl=[](uint32_t x,unsigned int n){
      return x<<n;
    };
    return shl(1,31) // enable bit
         | shl(bus_id,16)
         | shl(dev_id,11)
         | shl(func_id,8)
         | (reg_offset & 0xfcu);
  }

  kError ScanBus(uint8_t); // using at ScanFunction
  kError AddDevice(const Device& dev){
    if(pci::device_num==pci::devices.size())
      return KernelError(kError::kFull);
    pci::devices[device_num]=dev;
    device_num++;
    return KernelError(kError::kSuccess);
  }
  kError ScanFunction(uint8_t bus_id,uint8_t dev_id,uint8_t func_id){
    ClassCode class_code=GetClassCode(bus_id,dev_id,func_id);
    uint8_t header_type=GetHeaderType(bus_id,dev_id,func_id);
    Device dev{bus_id,dev_id,func_id,header_type,class_code};
    if(auto err=AddDevice(dev))
      return err;
    if(class_code.Match(0x06u,0x04u)){
      // standard PCI-PCI bridge
      uint32_t bus_numbers=ReadBusNumbers(bus_id,dev_id,func_id);
      uint8_t secondary_bus=(bus_numbers>>8) & 0xffu;
      return ScanBus(secondary_bus);
    }
    return KernelError(kError::kSuccess);
  }
  kError ScanDevice(uint8_t bus_id,uint8_t dev_id){
    if(auto err=ScanFunction(bus_id,dev_id,0))
      return err;
    if(IsSingleFuncDev(GetHeaderType(bus_id,dev_id,0)))
      return KernelError(kError::kSuccess);
    for(uint8_t func_id=1;func_id<8;func_id++){
      if(GetVendorId(bus_id,dev_id,func_id)==0xffffu)
        continue;
      if(auto err=ScanFunction(bus_id,dev_id,func_id))
        return err;
    }
    return KernelError(kError::kSuccess);
  }
  kError ScanBus(uint8_t bus_id){
    for(uint8_t dev_id=0;dev_id<32;dev_id++){
      if(GetVendorId(bus_id,dev_id,0)==0xffffu)
        continue;
      if(auto err=ScanDevice(bus_id,dev_id))
        return err;
    }
    return KernelError(kError::kSuccess);
  }
}

namespace pci {
  bool ClassCode::Match(uint8_t b){
    return b==base;
  }
  bool ClassCode::Match(uint8_t b,uint8_t s){
    return Match(b) && s==sub;
  }
  bool ClassCode::Match(uint8_t b,uint8_t s,uint8_t i){
    return Match(b,s) && i==iface;
  }

  void IoSetAddr(uint32_t addr){
    IoOut32(kConfigAddr,addr);
  }
  void IoWriteData(uint32_t val){
    IoOut32(kConfigData,val);
  }
  uint32_t IoReadData(){
    return IoIn32(kConfigData);
  }

  // お便利ツールを先に
  uint32_t ReadReg(const Device& dev,uint8_t addr){
    IoSetAddr(MakeConfigAddrVal(dev.bus_id,dev.dev_id,dev.func_id,addr));
    return IoReadData();
  }
  void WriteReg(const Device& dev,uint8_t addr,uint32_t val){
    IoSetAddr(MakeConfigAddrVal(dev.bus_id,dev.dev_id,dev.func_id,addr));
    IoWriteData(val);
  }
  uint16_t GetVendorId(
      uint8_t bus_id,uint8_t dev_id,uint8_t func_id){
    IoSetAddr(MakeConfigAddrVal(bus_id,dev_id,func_id,0));
    return IoReadData() & 0xffffu;
  }
  uint16_t GetVendorId(const Device& dev){
    return GetVendorId(dev.bus_id,dev.dev_id,dev.func_id);
  }
  uint16_t GetDeviceId(
      uint8_t bus_id,uint8_t dev_id,uint8_t func_id){
    IoSetAddr(MakeConfigAddrVal(bus_id,dev_id,func_id,0));
    return IoReadData()>>16;
  }
  uint8_t GetHeaderType(
      uint8_t bus_id,uint8_t dev_id,uint8_t func_id){
    IoSetAddr(MakeConfigAddrVal(bus_id,dev_id,func_id,0x0c));
    return (IoReadData()>>16) & 0xffu;
  }
  ClassCode GetClassCode(
      uint8_t bus_id,uint8_t dev_id,uint8_t func_id){
    IoSetAddr(MakeConfigAddrVal(bus_id,dev_id,func_id,0x08));
    auto reg=IoReadData();
    ClassCode class_code;
    class_code.base =(reg>>24) & 0xffu;
    class_code.sub  =(reg>>16) & 0xffu;
    class_code.iface=(reg>>8 ) & 0xffu;
    return class_code;
  }
  uint32_t ReadBusNumbers(
      uint8_t bus_id,uint8_t dev_id,uint8_t func_id){
    IoSetAddr(MakeConfigAddrVal(bus_id,dev_id,func_id,0x18));
    return IoReadData();
  }
  bool IsSingleFuncDev(uint8_t header_type){
    return !(header_type & 0x80u);
  }
  // お便利ツール編終わり

  kError ScanAllBus(){
    pci::device_num=0;
    auto header_type=GetHeaderType(0,0,0);

    if(IsSingleFuncDev(header_type))
      return ScanBus(0);
    for(uint8_t func_id=0;func_id<8;func_id++){
      if(GetVendorId(0,0,func_id)==0xffffu)
        continue;
      if(auto err=ScanBus(func_id))
        return err;
    }
    return KernelError(kError::kSuccess);
  }

  // よくわからん
  WithError<uint64_t> ReadBar(Device& dev,unsigned int bar_idx){
    if(bar_idx>=6)
      return {0,KernelError(kError::kIndexOutOfRange)};

    const uint8_t addr=0x10+4*bar_idx;
    const uint32_t bar=ReadReg(dev,addr);

    if(!(bar & 4u))
      return {bar,KernelError(kError::kSuccess)};
    if(bar_idx>=5)
      return {0,KernelError(kError::kIndexOutOfRange)};
    const uint32_t bar_upper=ReadReg(dev,addr+4);
    return {
      bar | (static_cast<uint64_t>(bar_upper)<<32),
      KernelError(kError::kSuccess)
    };
  }
}
