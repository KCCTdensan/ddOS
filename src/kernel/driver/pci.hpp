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
  WithError<uint64_t> ReadBar(Device& dev,unsigned int bar_idx);

  // 以下コピペ

  /** @brief PCI ケーパビリティレジスタの共通ヘッダ */
  union CapabilityHeader {
    uint32_t data;
    struct {
      uint32_t cap_id : 8;
      uint32_t next_ptr : 8;
      uint32_t cap : 16;
    } __attribute__((packed)) bits;
  } __attribute__((packed));

  const uint8_t kCapabilityMSI = 0x05;
  const uint8_t kCapabilityMSIX = 0x11;

  /** @brief 指定された PCI デバイスの指定されたケーパビリティレジスタを読み込む
   *
   * @param dev  ケーパビリティを読み込む PCI デバイス
   * @param addr  ケーパビリティレジスタのコンフィグレーション空間アドレス
   */
  CapabilityHeader ReadCapabilityHeader(const Device& dev, uint8_t addr);

  /** @brief MSI ケーパビリティ構造
   *
   * MSI ケーパビリティ構造は 64 ビットサポートの有無などで亜種が沢山ある．
   * この構造体は各亜種に対応するために最大の亜種に合わせてメンバを定義してある．
   */
  struct MSICapability {
    union {
      uint32_t data;
      struct {
        uint32_t cap_id : 8;
        uint32_t next_ptr : 8;
        uint32_t msi_enable : 1;
        uint32_t multi_msg_capable : 3;
        uint32_t multi_msg_enable : 3;
        uint32_t addr_64_capable : 1;
        uint32_t per_vector_mask_capable : 1;
        uint32_t : 7;
      } __attribute__((packed)) bits;
    } __attribute__((packed)) header ;

    uint32_t msg_addr;
    uint32_t msg_upper_addr;
    uint32_t msg_data;
    uint32_t mask_bits;
    uint32_t pending_bits;
  } __attribute__((packed));

  /** @brief MSI または MSI-X 割り込みを設定する
   *
   * @param dev  設定対象の PCI デバイス
   * @param msg_addr  割り込み発生時にメッセージを書き込む先のアドレス
   * @param msg_data  割り込み発生時に書き込むメッセージの値
   * @param num_vector_exponent  割り当てるベクタ数（2^n の n を指定）
   */
  kError ConfigureMSI(const Device& dev, uint32_t msg_addr, uint32_t msg_data,
                     unsigned int num_vector_exponent);

  enum class MSITriggerMode {
    kEdge = 0,
    kLevel = 1
  };

  enum class MSIDeliveryMode {
    kFixed          = 0b000,
    kLowestPriority = 0b001,
    kSMI            = 0b010,
    kNMI            = 0b100,
    kINIT           = 0b101,
    kExtINT         = 0b111,
  };

  kError ConfigureMSIFixedDestination(
      const Device& dev, uint8_t apic_id,
      MSITriggerMode trigger_mode, MSIDeliveryMode delivery_mode,
      uint8_t vector, unsigned int num_vector_exponent);
}

void InitializePCI();
