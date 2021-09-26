/**
 * @file usb/device.hpp
 *
 * USB デバイスを表すクラスと関連機能．
 */

#pragma once

#include <array>
#include <vector>

#include "error.hpp"
#include "arraymap.hpp"
#include "classdriver/base.hpp"
#include "descriptor.hpp"
#include "endpoint.hpp"
#include "setupdata.hpp"

namespace usb {
  class Device {
   public:
    virtual ~Device();
    virtual kError ControlIn(EndpointID ep_id, SetupData setup_data,
                            void* buf, int len, ClassDriver* issuer);
    virtual kError ControlOut(EndpointID ep_id, SetupData setup_data,
                             const void* buf, int len, ClassDriver* issuer);
    virtual kError NormalIn(EndpointID ep_id, void* buf, int len);
    virtual kError NormalOut(EndpointID ep_id, const void* buf, int len);

    kError StartInitialize();
    bool IsInitialized() { return is_initialized_; }
    auto& EndpointConfigs() const { return ep_configs_; }
    kError OnEndpointsConfigured();

    uint8_t* Buffer() { return buf_.data(); }
    const DeviceDescriptor& DeviceDesc() const { return device_desc_; }

   protected:
    kError OnControlCompleted(EndpointID ep_id, SetupData setup_data,
                             const void* buf, int len);
    kError OnNormalCompleted(EndpointID ep_id, const void* buf, int len);

   private:
    std::vector<ClassDriver*> class_drivers_{};

    std::array<uint8_t, 256> buf_{};
    DeviceDescriptor device_desc_;

    // following fields are used during initialization
    uint8_t num_configurations_;
    uint8_t config_index_;

    kError OnDeviceDescriptorReceived(const uint8_t* buf, int len);
    kError OnConfigurationDescriptorReceived(const uint8_t* buf, int len);
    kError OnSetConfigurationCompleted(uint8_t config_value);

    bool is_initialized_ = false;
    int initialize_phase_ = 0;
    std::vector<EndpointConfig> ep_configs_{};
    kError InitializePhase1(const uint8_t* buf, int len);
    kError InitializePhase2(const uint8_t* buf, int len);
    kError InitializePhase3(uint8_t config_value);
    kError InitializePhase4();

    /** OnControlCompleted の中で要求の発行元を特定するためのマップ構造．
     * ControlOut または ControlIn を発行したときに発行元が登録される．
     */
    ArrayMap<SetupData, ClassDriver*, 4> event_waiters_{};
  };

  kError GetDescriptor(Device& dev, EndpointID ep_id,
                      uint8_t desc_type, uint8_t desc_index,
                      void* buf, int len, bool debug = false);
  kError SetConfiguration(Device& dev, EndpointID ep_id,
                         uint8_t config_value, bool debug = false);
}
