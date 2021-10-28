int tsprintf(T ...)(char* buf, size_t size, string fmt, T args) { // tiny sprintf
}

void memcpy(char* to_buf, char* from_buf, size_t n) {
  foreach(_; 0 .. n) *to_buf++=*from_buf++;
}
