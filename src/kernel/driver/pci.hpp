#pragma once

#include <cstdint>
#include <array>

#include "error.hpp"

namespace pci {
  struct ClassCode {
    uint8_t base,sub,iface;
    bool Match(uint8_t b);
    bool Match(uint8_t b,uint8_t s);
    bool Match(uint8_t b,uint8_t s,uint8_t i);
  };
  struct Device {
    uint8_t bus_id,dev_id,func_id,header_type;
    ClassCode class_code;
  };

  // あ
  inline std::array<Device,32> devices;
  inline int device_num;

  const uint16_t kConfigAddr=0x0cf8;
  const uint16_t kConfigData=0x0cfc;

  // IOアドレス空間の読み書き
  // uses driver/asmfunc.asm
  void IoSetAddr(uint32_t);
  void IoWriteData(uint32_t);
  uint32_t IoReadData();

  kError ScanAllBus();

  // お便利ツール
  uint32_t ReadReg(const Device& dev,uint8_t addr);
  void WriteReg(const Device& dev,uint8_t addr,uint32_t val);
  uint16_t GetVendorId(const Device& dev);
  uint16_t GetVendorId(uint8_t bus_id,uint8_t dev_id,uint8_t func_id);
  uint16_t GetDeviceId(uint8_t bus_id,uint8_t dev_id,uint8_t func_id);
  uint8_t GetHeaderType(uint8_t bus_id,uint8_t dev_id,uint8_t func_id);
  ClassCode GetClassCode(uint8_t bus_id,uint8_t dev_id,uint8_t func_id);
  uint32_t ReadBusNumbers(uint8_t bus_id,uint8_t dev_id,uint8_t func_id);
  bool IsSingleFuncDev(uint8_t header_type);
}
