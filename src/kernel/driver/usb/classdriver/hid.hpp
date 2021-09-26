/**
 * @file usb/classdriver/hid.hpp
 *
 * HID base class driver.
 */

#pragma once

#include "base.hpp"

namespace usb {
  class HIDBaseDriver : public ClassDriver {
   public:
    HIDBaseDriver(Device* dev, int interface_index, int in_packet_size);
    kError Initialize() override;
    kError SetEndpoint(const std::vector<EndpointConfig>& configs) override;
    kError OnEndpointsConfigured() override;
    kError OnControlCompleted(EndpointID ep_id, SetupData setup_data,
                             const void* buf, int len) override;
    kError OnNormalCompleted(EndpointID ep_id, const void* buf, int len) override;

    virtual kError OnDataReceived() = 0;
    const static size_t kBufferSize = 1024;
    const std::array<uint8_t, kBufferSize>& Buffer() const { return buf_; }
    const std::array<uint8_t, kBufferSize>& PreviousBuffer() const { return previous_buf_; }

   private:
    EndpointID ep_interrupt_in_;
    EndpointID ep_interrupt_out_;
    const int interface_index_;
    int in_packet_size_;
    int initialize_phase_{0};

    std::array<uint8_t, kBufferSize> buf_{}, previous_buf_{};
  };
}
