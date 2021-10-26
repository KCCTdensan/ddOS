#pragma once

#include <stdint.h>

struct MemMap {
  unsigned long long buf_s; // size
  void* buf;
  unsigned long long map_s;
  unsigned long long map_key; // gBS->ExitBootServices() 用らしい。マップを識別するための値
  unsigned long long desc_s;
  uint32_t desc_ver; // 使わん
};
