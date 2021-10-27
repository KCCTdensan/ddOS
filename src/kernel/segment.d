import std.bitmanip;

enum DescriptorType {
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

union SegmentDescriptor {
  ulong data;
  mixin(bitfields!(
    ulong, "limit_low",       16,
    ulong, "base_low",        16,
    ulong, "base_middle",     8,
    DescriptorType, "type",   4,
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

private SegmentDescriptor[3] gdt;

void SetCodeSegment(ref SegmentDescriptor desc,
                    DescriptorType type,
                    uint descriptor_privilege_level,
                    uint base,
                    uint limit) {
  desc.data = 0;

  desc.bits.base_low = base & 0xffffu;
  desc.bits.base_middle = (base >> 16) & 0xffu;
  desc.bits.base_high = (base >> 24) & 0xffu;

  desc.bits.limit_low = limit & 0xffffu;
  desc.bits.limit_high = (limit >> 16) & 0xfu;

  desc.bits.type = type;
  desc.bits.system_segment = 1; // 1: code & data segment
  desc.bits.descriptor_privilege_level = descriptor_privilege_level;
  desc.bits.present = 1;
  desc.bits.available = 0;
  desc.bits.long_mode = 1;
  desc.bits.default_operation_size = 0; // should be 0 when long_mode == 1
  desc.bits.granularity = 1;
}

void SetDataSegment(ref SegmentDescriptor desc,
                    DescriptorType type,
                    uint descriptor_privilege_level,
                    uint base,
                    uint limit) {
  SetCodeSegment(desc, type, descriptor_privilege_level, base, limit);
  desc.bits.long_mode = 0;
  desc.bits.default_operation_size = 1; // 32-bit stack segment
}

void SetupSegments() {
  gdt[0].data = 0;
  SetCodeSegment(gdt[1], DescriptorType.kExecuteRead, 0, 0, 0xfffff);
  SetDataSegment(gdt[2], DescriptorType.kReadWrite, 0, 0, 0xfffff);
  LoadGDT(gdt.sizeof - 1, cast(uint)&gdt[0]);
}
