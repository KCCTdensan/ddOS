import std.bitmanip;

enum SegDescType {
  // system segment & gate descriptor types
  kUpper8Bytes   = 0,
  kLDT           = 2,
  kTSSAvailable  = 9,
  kTSSBusy       = 11,
  kCallGate      = 12,
  kInterruptGate = 14,
  kTrapGate      = 15,

  // code & data segment types
  kReadWrite     = 2,
  kExecuteRead   = 10,
}

union SegDesc {
  ulong data;
  mixin(bitfields!(
    ulong, "limit_low",       16,
    ulong, "base_low",        16,
    ulong, "base_middle",     8,
    SegDescType, "type",      4,
    ulong, "system_segment",  1,
    ulong, "descriptor_privilege_level", 2,
    ulong, "present",         1,
    ulong, "limit_high",      4,
    ulong, "available",       1,
    ulong, "long_mode",       1,
    ulong, "default_operation_size", 1,
    ulong, "granularity",     1,
    ulong, "base_high",       8,
  ));
}

void SetCodeSegment(ref SegDesc desc,
                    SegDescType type,
                    uint descriptor_privilege_level,
                    uint base,
                    uint limit) {
  desc.data = 0;

  desc.base_low = base & 0xffffu;
  desc.base_middle = (base >> 16) & 0xffu;
  desc.base_high = (base >> 24) & 0xffu;

  desc.limit_low = limit & 0xffffu;
  desc.limit_high = (limit >> 16) & 0xfu;

  desc.type = type;
  desc.system_segment = 1; // 1: code & data segment
  desc.descriptor_privilege_level = descriptor_privilege_level;
  desc.present = 1;
  desc.available = 0;
  desc.long_mode = 1;
  desc.default_operation_size = 0; // should be 0 when long_mode == 1
  desc.granularity = 1;
}

void SetDataSegment(ref SegDesc desc,
                    SegDescType type,
                    uint descriptor_privilege_level,
                    uint base,
                    uint limit) {
  SetCodeSegment(desc, type, descriptor_privilege_level, base, limit);
  desc.long_mode = 0;
  desc.default_operation_size = 1; // 32-bit stack segment
}
