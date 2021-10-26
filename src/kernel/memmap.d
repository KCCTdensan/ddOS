// これだけ?!?!

struct MemMap {
  ulong buf_s; // size
  void* buf;
  ulong map_s;
  ulong map_key; // gBS->ExitBootServices() 用らしい。マップを識別するための値
  ulong desc_s;
  uint desc_ver; // 使わん
}

struct MemDesc {
  uint type;
  uint physical_start; // uintptr_t
  uint virtual_start; //
  ulong number_of_pages;
  ulong attribute;
}

enum MemType {
  kEfiReservedMemoryType,
  kEfiLoaderCode,
  kEfiLoaderData,
  kEfiBootServicesCode,
  kEfiBootServicesData,
  kEfiRuntimeServicesCode,
  kEfiRuntimeServicesData,
  kEfiConventionalMemory,
  kEfiUnusableMemory,
  kEfiACPIReclaimMemory,
  kEfiACPIMemoryNVS,
  kEfiMemoryMappedIO,
  kEfiMemoryMappedIOPortSpace,
  kEfiPalCode,
  kEfiPersistentMemory,
  kEfiMaxMemoryType,
}

//inline bool operator==(uint32_t lhs, MemoryType rhs) {
//  return lhs == static_cast<uint32_t>(rhs);
//}

//inline bool operator==(MemoryType lhs, uint32_t rhs) {
//  return rhs == lhs;
//}

bool IsAvailable(MemType type) {
  return type == MemType.kEfiBootServicesCode
      || type == MemType.kEfiBootServicesData
      || type == MemType.kEfiConventionalMemory;
}

//const int kUEFIPageSize = 4096;
