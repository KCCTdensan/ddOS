#include "pci.hpp"
#include "asmfunc.h"

namespace{
  using namespace pci;

  uint32_t MakeConfigAddrVal(uint8_t bus,
                             uint8_t dev,
                             uint8_t func,
                             uint8_t reg){
    auto shl=[](uint32_t x,unsigned int n){
      return x<<n;
    };
    return shl(1,31)
         | shl(bus,16)
         | shl(dev,11)
         | shl(func,8)
         | (reg & 0xfcu);
  }
}

namespace pci{
  void IoSetAddr(uint32_t addr){
    IoOut32(kConfigAddr,addr);
  }
  void IoWriteData(uint32_t val){
    IoOut32(kConfigData,val);
  }
  uint32_t IoReadData(){
    return IoIn32(kConfigData);
  }

  uint16_t GetVendorId(uint8_t bus,
                       uint8_t dev,
                       uint8_t func){
    IoSetAddr(MakeConfigAddrVal(bus,dev,func,0));
    return IoReadData()&0xffffu;
  }
}
