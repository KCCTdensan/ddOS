int tsprintf(T ...)(char* buf, size_t buf_len, string fmtstr, T args) { // tiny sprintf
  char[fmtstr.length+1] fmtarr = fmtstr.dup;
  char* fmt = fmtarr.ptr;
  int width,size; // format用
  bool zeroflag;
  while(*fmt) {
    if(*fmt == '%') {
      width = 0;
      zeroflag = false;
      ++fmt;

      // length
      if(*fmt == '0') {
        ++fmt;
        zeroflag = true;
      }
      if(('0' <= *fmt) && (*fmt <= '9')) {
        width = *fmt++ - '0';
      }

      // type or char
      switch(*fmt) {
        case 'd':
          size = ;
          break;
        case 'x':
          size = ;
          break;
        case 'c':
          size = ;
          break;
        case 's':
          size = ;
          break;
        default: // そんなわけないだろ
          *buf++ = *fmt;
          ++len;
      }

      buf += size;
      len += size;
      ++fmt;
    } else { // フォーマットの無い普通の文字
      *buf++ = *fmt++;
      ++len;
    }
  }
  *buf = '\0';
  return len;
}

void memcpy(char* to_buf, char* from_buf, size_t n) {
  foreach(_; 0 .. n) *to_buf++=*from_buf++;
}
