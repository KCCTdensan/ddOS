private {
  const ulong kPageSize4K = 4096;
  const ulong kPageSize2M = 512 * kPageSize4K;
  const ulong kPageSize1G = 512 * kPageSize2M;

  align(kPageSize4K) ulong[512] pml4_table;
  align(kPageSize4K) ulong[512] pdp_table;
  align(kPageSize4K) ulong[512][kPageDirectoryCount] page_directory;
}

const size_t kPageDirectoryCount = 64;

void SetupIdentityPageTable() {
  pml4_table[0] = cast(ulong)&pdp_table[0] | 0x003;
  foreach(int i_pdpt; 0 .. page_directory.length) {
    pdp_table[i_pdpt] = cast(ulong)&page_directory[i_pdpt] | 0x003;
    foreach(int i_pd; 0 .. 512)
      page_directory[i_pdpt][i_pd] = i_pdpt * kPageSize1G + i_pd * kPageSize2M | 0x083;
  }

  SetCR3(cast(ulong)&pml4_table[0]);
}
