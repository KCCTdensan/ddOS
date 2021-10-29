import error;

@property ulong KiB(ulong kib) { return kib * 1024; }
@property ulong MiB(ulong mib) { return mib * 1024.KiB; }
@property ulong GiB(ulong gib) { return gib * 1024.MiB; }

// フレームの大きさ[byte]
const ulong kBytesPerFrame = 4.KiB;

struct FrameID {
  this(size_t id_) { this.id = id_; }
  @property ID() const {
    return this.id;
  }
  @property void* Frame() const {
    return cast(void*)(this.id*kBytesPerFrame);
  }
private:
  size_t id;
}

const FrameID kNullFrame = size_t.max;

struct BitmapMemoryManager {
  alias MapLineType = ulong; // ビットマップ配列の要素型

  const auto kMaxPhysicalMemoryBytes = 128.GiB;
  const auto kFrameCount = kMaxPhysicalMemoryBytes / kBytesPerFrame;
  const size_t kBitsPerMapLine = 8 * MapLineType.sizeof; // ビットマップ配列の要素が扱うフレーム数

  WithError!FrameID Allocate(size_t num_frames) {
    size_t start_frame_id = range_begin.ID;
    while(true) {
      size_t i = 0;
      for(; i < num_frames; ++i) {
        if(start_frame_id + i >= range_end.ID) // ?!?!
          return WithError!FrameID(KernelError(KError.Code.kNoEnoughMemory), kNullFrame);
        if(GetBit(FrameID(start_frame_id + i))) break;
      }
      if(i == num_frames) { // num_framesピッタリの空きがあった
        MarkAllocated(FrameID(start_frame_id), num_frames);
        return WithError!FrameID(KernelError(KError.Code.kSuccess), FrameID(start_frame_id));
      }
      // 見付からなかったので次のフレームから再検索
      start_frame_id += i + 1;
    }
  }
  KError Free(FrameID start_frame, size_t num_frames) {
    foreach(size_t i; 0 .. num_frames)
      SetBit(FrameID(start_frame.ID + i), false);
    return KernelError(KError.Code.kSuccess);
  }

  void MarkAllocated(FrameID start_frame, size_t num_frames) {
    foreach(size_t i; 0 .. num_frames)
      SetBit(FrameID(start_frame.ID + i), true);
  }
  void SetMemoryRange(FrameID begin, FrameID end) {
    this.range_begin = begin;
    this.range_end = end;
  }

private:
  MapLineType[kFrameCount / kBitsPerMapLine] alloc_map;
  FrameID range_begin = FrameID(0), // この構造体は range_begin .. range_end を扱う
          range_end = FrameID(kFrameCount); //

  bool GetBit(FrameID frame) const {
    auto line_index = frame.ID / kBitsPerMapLine;
    auto bit_index = frame.ID % kBitsPerMapLine;

    return (alloc_map[line_index] & (cast(MapLineType)1 << bit_index)) != 0;
  }

  void SetBit(FrameID frame, bool allocated) {
    auto line_index = frame.ID / kBitsPerMapLine;
    auto bit_index = frame.ID % kBitsPerMapLine;

    if(allocated) {
      alloc_map[line_index] |= (cast(MapLineType)1 << bit_index);
    } else {
      alloc_map[line_index] &= ~(cast(MapLineType)1 << bit_index);
    }
  }
}
