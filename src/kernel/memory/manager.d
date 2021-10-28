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



/** @brief ビットマップ配列を用いてフレーム単位でメモリ管理するクラス．
 *
 * 1 ビットを 1 フレームに対応させて，ビットマップにより空きフレームを管理する．
 * 配列 alloc_map の各ビットがフレームに対応し，0 なら空き，1 なら使用中．
 * alloc_map[n] の m ビット目が対応する物理アドレスは次の式で求まる：
 *   kFrameBytes * (n * kBitsPerMapLine + m)
 */
struct BitmapMemoryManager {
  /** @brief このメモリ管理クラスで扱える最大の物理メモリ量（バイト） */
  static const auto kMaxPhysicalMemoryBytes{128_GiB};
  /** @brief kMaxPhysicalMemoryBytes までの物理メモリを扱うために必要なフレーム数 */
  static const auto kFrameCount{kMaxPhysicalMemoryBytes / kBytesPerFrame};

  /** @brief ビットマップ配列の要素型 */
  using MapLineType = unsigned long;
  /** @brief ビットマップ配列の 1 つの要素のビット数 == フレーム数 */
  static const size_t kBitsPerMapLine{8 * sizeof(MapLineType)};

  this() alloc_map_{}, range_begin_{FrameID{0}}, range_end_{FrameID{kFrameCount}} {};

  /** @brief 要求されたフレーム数の領域を確保して先頭のフレーム ID を返す */
  WithError<FrameID> Allocate(size_t num_frames) {
  size_t start_frame_id = range_begin_.ID();
  while (true) {
    size_t i = 0;
    for (; i < num_frames; ++i) {
      if (start_frame_id + i >= range_end_.ID()) {
        return {kNullFrame, MAKE_ERROR(Error::kNoEnoughMemory)};
      }
      if (GetBit(FrameID{start_frame_id + i})) {
        // "start_frame_id + i" にあるフレームは割り当て済み
        break;
      }
    }
    if (i == num_frames) {
      // num_frames 分の空きが見つかった
      MarkAllocated(FrameID{start_frame_id}, num_frames);
      return {
        FrameID{start_frame_id},
        MAKE_ERROR(Error::kSuccess),
      };
    }
    // 次のフレームから再検索
    start_frame_id += i + 1;
  }
};
  Error Free(FrameID start_frame, size_t num_frames) {
  for (size_t i = 0; i < num_frames; ++i) {
    SetBit(FrameID{start_frame.ID() + i}, false);
  }
  return MAKE_ERROR(Error::kSuccess);
}
  void MarkAllocated(FrameID start_frame, size_t num_frames) {
  for (size_t i = 0; i < num_frames; ++i) {
    SetBit(FrameID{start_frame.ID() + i}, true);
  }
}

  /** @brief このメモリマネージャで扱うメモリ範囲を設定する．
   * この呼び出し以降，Allocate によるメモリ割り当ては設定された範囲内でのみ行われる．
   *
   * @param range_begin_ メモリ範囲の始点
   * @param range_end_   メモリ範囲の終点．最終フレームの次のフレーム．
   */
  void SetMemoryRange(FrameID range_begin, FrameID range_end) {
  range_begin_ = range_begin;
  range_end_ = range_end;
}

 private:
  std::array<MapLineType, kFrameCount / kBitsPerMapLine> alloc_map_;
  /** @brief このメモリマネージャで扱うメモリ範囲の始点． */
  FrameID range_begin_;
  /** @brief このメモリマネージャで扱うメモリ範囲の終点．最終フレームの次のフレーム． */
  FrameID range_end_;

  bool GetBit(FrameID frame) const {
  auto line_index = frame.ID() / kBitsPerMapLine;
  auto bit_index = frame.ID() % kBitsPerMapLine;

  return (alloc_map_[line_index] & (static_cast<MapLineType>(1) << bit_index)) != 0;
}

  void SetBit(FrameID frame, bool allocated) {
  auto line_index = frame.ID() / kBitsPerMapLine;
  auto bit_index = frame.ID() % kBitsPerMapLine;

  if (allocated) {
    alloc_map_[line_index] |= (static_cast<MapLineType>(1) << bit_index);
  } else {
    alloc_map_[line_index] &= ~(static_cast<MapLineType>(1) << bit_index);
  }
}

}
