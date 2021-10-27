#include <cstdint>

alignas(16) // dでやったらリンクエラー
uint8_t kernel_main_stack[1024 * 1024];
