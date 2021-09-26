#include "device.hpp"

#include "setupdata.hpp"
#include "classdriver/base.hpp"
#include "classdriver/cdc.hpp"
#include "classdriver/keyboard.hpp"
#include "classdriver/mouse.hpp"

#include "log.hpp"

namespace {
  class ConfigurationDescriptorReader {
   public:
    ConfigurationDescriptorReader(const uint8_t* desc_buf, int len)
      : desc_buf_{desc_buf},
        desc_buf_len_{len},
        p_{desc_buf} {
    }

    const uint8_t* Next() {
      p_ += p_[0];
      if (p_ < desc_buf_ + desc_buf_len_) {
        return p_;
      }
      return nullptr;
    }

    template <class T>
    const T* Next() {
      while (auto n = Next()) {
        if (auto d = usb::DescriptorDynamicCast<T>(n)) {
          return d;
        }
      }
      return nullptr;
    }

   private:
    const uint8_t* const desc_buf_;
    const int desc_buf_len_;
    const uint8_t* p_;
  };

  usb::EndpointConfig MakeEPConfig(const usb::EndpointDescriptor& ep_desc) {
    usb::EndpointConfig conf;
    conf.ep_id = usb::EndpointID{
      ep_desc.endpoint_address.bits.number,
      ep_desc.endpoint_address.bits.dir_in == 1
    };
    conf.ep_type = static_cast<usb::EndpointType>(ep_desc.attributes.bits.transfer_type);
    conf.max_packet_size = ep_desc.max_packet_size;
    conf.interval = ep_desc.interval;
    return conf;
  }

  void PutLog(LogLevel level, const usb::InterfaceDescriptor& if_desc) {
    PutLog(level, "Interface Descriptor: class=%d, sub=%d, protocol=%d\n",
        if_desc.interface_class,
        if_desc.interface_sub_class,
        if_desc.interface_protocol);
  }

  void PutLog(LogLevel level, const usb::EndpointConfig& conf) {
    PutLog(level, "EndpointConf: ep_id=%d, ep_type=%d"
        ", max_packet_size=%d, interval=%d\n",
        conf.ep_id.Address(), conf.ep_type,
        conf.max_packet_size, conf.interval);
  }

  void PutLog(LogLevel level, const usb::HIDDescriptor& hid_desc) {
    PutLog(level, "HID Descriptor: release=0x%02x, num_desc=%d",
        hid_desc.hid_release,
        hid_desc.num_descriptors);
    for (int i = 0; i < hid_desc.num_descriptors; ++i) {
      PutLog(level, ", desc_type=%d, len=%d",
          hid_desc.GetClassDescriptor(i)->descriptor_type,
          hid_desc.GetClassDescriptor(i)->descriptor_length);
    }
    PutLog(level, "\n");
  }

  usb::ClassDriver* NewClassDriver(usb::Device* dev, const usb::InterfaceDescriptor& if_desc) {
    if (if_desc.interface_class == 3 &&
        if_desc.interface_sub_class == 1) {  // HID boot interface
      if (if_desc.interface_protocol == 1) {  // keyboard
        auto keyboard_driver = new usb::HIDKeyboardDriver{dev, if_desc.interface_number};
        if (usb::HIDKeyboardDriver::default_observer) {
          keyboard_driver->SubscribeKeyPush(usb::HIDKeyboardDriver::default_observer);
        }
        return keyboard_driver;
      } else if (if_desc.interface_protocol == 2) {  // mouse
        auto mouse_driver = new usb::HIDMouseDriver{dev, if_desc.interface_number};
        if (usb::HIDMouseDriver::default_observer) {
          mouse_driver->SubscribeMouseMove(usb::HIDMouseDriver::default_observer);
        }
        return mouse_driver;
      }
    }
    return nullptr;
  }

  WithError<usb::ClassDriver*> NewClassDriver(
      std::vector<usb::EndpointConfig>& ep_configs,
      usb::Device* dev,
      ConfigurationDescriptorReader& conf_reader) {
    using namespace usb::cdc;
    PutLog(kLogWarn, "creating class driver for class=%d\n", dev->DeviceDesc().device_class);

    if (dev->DeviceDesc().device_class == 2) {
      const usb::InterfaceDescriptor* if_comm = nullptr;
      const usb::InterfaceDescriptor* if_data = nullptr;
      while (auto if_desc = conf_reader.Next<usb::InterfaceDescriptor>()) {
        PutLog(kLogWarn, *if_desc);
        if (if_desc->interface_class == 2) {
          if_comm = if_desc;
        } else if (if_desc->interface_class == 10) {
          if_data = if_desc;
        }

        for (int i = 0; i < if_desc->num_endpoints; ++i) {
          auto desc = conf_reader.Next();
          if (auto ep_desc = usb::DescriptorDynamicCast<usb::EndpointDescriptor>(desc)) {
            ep_configs.push_back(MakeEPConfig(*ep_desc));
            PutLog(kLogWarn, ep_configs.back());
          } else if (auto cdc = FuncDescDynamicCast<HeaderDescriptor>(desc)) {
            PutLog(kLogWarn, "kHeader: cdc=%04x\n", cdc->cdc);
          } else if (auto call = FuncDescDynamicCast<CMDescriptor>(desc)) {
            PutLog(kLogWarn, "kCM: cap=%x, dat_if=%d\n",
                call->capabilities.data, call->data_interface);
          } else if (auto acm = FuncDescDynamicCast<ACMDescriptor>(desc)) {
            PutLog(kLogWarn, "kACM: cap=%x\n", acm->capabilities.data);
          } else if (auto uni = FuncDescDynamicCast<UnionDescriptor>(desc)) {
            PutLog(kLogWarn, "kUnion: ctr_if=%d\n", uni->control_interface);
          } else {
            PutLog(kLogWarn, "unknown descriptor. type = %d\n", desc[1]);
          }
        }
      }

      usb::cdc::driver = new usb::cdc::CDCDriver{dev, if_comm, if_data};
      return { usb::cdc::driver, KernelError(kError::kSuccess) };
    }
    return { nullptr, KernelError(kError::kNotImplemented) };
  }
}

namespace usb {
  Device::~Device() {
  }

  kError Device::ControlIn(EndpointID ep_id, SetupData setup_data,
                          void* buf, int len, ClassDriver* issuer) {
    if (issuer) {
      event_waiters_.Put(setup_data, issuer);
    }
    return KernelError(kError::kSuccess);
  }

  kError Device::ControlOut(EndpointID ep_id, SetupData setup_data,
                           const void* buf, int len, ClassDriver* issuer) {
    if (issuer) {
      event_waiters_.Put(setup_data, issuer);
    }
    return KernelError(kError::kSuccess);
  }

  kError Device::NormalIn(EndpointID ep_id, void* buf, int len) {
    return KernelError(kError::kSuccess);
  }

  kError Device::NormalOut(EndpointID ep_id, const void* buf, int len) {
    return KernelError(kError::kSuccess);
  }

  kError Device::StartInitialize() {
    is_initialized_ = false;
    initialize_phase_ = 1;
    return GetDescriptor(*this, kDefaultControlPipeID, DeviceDescriptor::kType, 0,
                         buf_.data(), buf_.size(), true);
  }

  kError Device::OnEndpointsConfigured() {
    for (auto class_driver : class_drivers_) {
      if (auto err = class_driver->OnEndpointsConfigured()) {
        return err;
      }
    }
    return KernelError(kError::kSuccess);
  }

  kError Device::OnControlCompleted(EndpointID ep_id, SetupData setup_data,
                                   const void* buf, int len) {
    PutLog(kLogDebug, "Device::OnControlCompleted: buf 0x%08lx, len %d, dir %d\n",
        reinterpret_cast<uintptr_t>(buf), len, setup_data.request_type.bits.direction);
    if (is_initialized_) {
      if (auto w = event_waiters_.Get(setup_data)) {
        return w.value()->OnControlCompleted(ep_id, setup_data, buf, len);
      }
      return KernelError(kError::kNoWaiter);
    }

    const uint8_t* buf8 = reinterpret_cast<const uint8_t*>(buf);
    if (initialize_phase_ == 1) {
      if (setup_data.request == request::kGetDescriptor &&
          DescriptorDynamicCast<DeviceDescriptor>(buf8)) {
        return InitializePhase1(buf8, len);
      }
      return KernelError(kError::kInvalidPhase);
    } else if (initialize_phase_ == 2) {
      if (setup_data.request == request::kGetDescriptor &&
          DescriptorDynamicCast<ConfigurationDescriptor>(buf8)) {
        return InitializePhase2(buf8, len);
      }
      return KernelError(kError::kInvalidPhase);
    } else if (initialize_phase_ == 3) {
      if (setup_data.request == request::kSetConfiguration) {
        return InitializePhase3(setup_data.value & 0xffu);
      }
      return KernelError(kError::kInvalidPhase);
    }

    return KernelError(kError::kNotImplemented);
  }

  kError Device::OnNormalCompleted(EndpointID ep_id, const void* buf, int len) {
    PutLog(kLogDebug, "Device::OnNormalCompleted: ep addr %d\n", ep_id.Address());
    for (auto class_driver : class_drivers_) {
      auto err = class_driver->OnNormalCompleted(ep_id, buf, len);
      if (err.Cause() == kError::kEndpointNotInCharge) {
        continue;
      } else if (err) {
        return err;
      }
    }
    return KernelError(kError::kSuccess);
  }

  kError Device::InitializePhase1(const uint8_t* buf, int len) {
    if (len != sizeof(DeviceDescriptor)) {
      return KernelError(kError::kInvalidDescriptor);
    }

    memcpy(&device_desc_, buf, len);
    num_configurations_ = device_desc_.num_configurations;
    config_index_ = 0;
    initialize_phase_ = 2;
    PutLog(kLogDebug, "issuing GetDesc(Config): index=%d)\n", config_index_);
    return GetDescriptor(*this, kDefaultControlPipeID,
                         ConfigurationDescriptor::kType, config_index_,
                         buf_.data(), buf_.size(), true);
  }

  kError Device::InitializePhase2(const uint8_t* buf, int len) {
    auto conf_desc = DescriptorDynamicCast<ConfigurationDescriptor>(buf);
    if (conf_desc == nullptr) {
      return KernelError(kError::kInvalidDescriptor);
    }
    ConfigurationDescriptorReader config_reader{buf, len};

    if (device_desc_.device_class != 0) {
      auto [ class_driver, err ] =
        NewClassDriver(ep_configs_, this, config_reader);
      if (err) {
        return err;
      }
      class_drivers_.push_back(class_driver);
    } else {
      bool no_class_driver = true;
      while (auto if_desc = config_reader.Next<InterfaceDescriptor>()) {
        PutLog(kLogDebug, *if_desc);

        auto class_driver = NewClassDriver(this, *if_desc);
        if (class_driver == nullptr) {
          // 非対応デバイス．次の interface を調べる．
          continue;
        }
        no_class_driver = false;
        class_drivers_.push_back(class_driver);

        for (int ep_index = 0; ep_index < if_desc->num_endpoints;) {
          auto desc = config_reader.Next();
          if (auto ep_desc = DescriptorDynamicCast<EndpointDescriptor>(desc)) {
            ep_configs_.push_back(MakeEPConfig(*ep_desc));
            PutLog(kLogDebug, ep_configs_.back());
            ++ep_index;
          } else if (auto hid_desc = DescriptorDynamicCast<HIDDescriptor>(desc)) {
            PutLog(kLogDebug, *hid_desc);
          }
        }
        break;
      }

      if (no_class_driver) {
        return KernelError(kError::kSuccess);
      }
    }

    initialize_phase_ = 3;
    PutLog(kLogDebug, "issuing SetConfiguration: conf_val=%d\n",
        conf_desc->configuration_value);
    return SetConfiguration(*this, kDefaultControlPipeID,
                            conf_desc->configuration_value, true);
  }

  kError Device::InitializePhase3(uint8_t config_value) {
    for (auto class_driver : class_drivers_) {
      class_driver->SetEndpoint(ep_configs_);
    }
    initialize_phase_ = 4;
    is_initialized_ = true;
    return KernelError(kError::kSuccess);
  }

  kError GetDescriptor(Device& dev, EndpointID ep_id,
                      uint8_t desc_type, uint8_t desc_index,
                      void* buf, int len, bool debug) {
    SetupData setup_data{};
    setup_data.request_type.bits.direction = request_type::kIn;
    setup_data.request_type.bits.type = request_type::kStandard;
    setup_data.request_type.bits.recipient = request_type::kDevice;
    setup_data.request = request::kGetDescriptor;
    setup_data.value = (static_cast<uint16_t>(desc_type) << 8) | desc_index;
    setup_data.index = 0;
    setup_data.length = len;
    return dev.ControlIn(ep_id, setup_data, buf, len, nullptr);
  }

  kError SetConfiguration(Device& dev, EndpointID ep_id,
                         uint8_t config_value, bool debug) {
    SetupData setup_data{};
    setup_data.request_type.bits.direction = request_type::kOut;
    setup_data.request_type.bits.type = request_type::kStandard;
    setup_data.request_type.bits.recipient = request_type::kDevice;
    setup_data.request = request::kSetConfiguration;
    setup_data.value = config_value;
    setup_data.index = 0;
    setup_data.length = 0;
    return dev.ControlOut(ep_id, setup_data, nullptr, 0, nullptr);
  }
}
