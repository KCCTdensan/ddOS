module lib.string;

// tiny sprintf
int tsprintf(T ...)(char* buf, char* fmt, T args) {
  int len = 0;
  static if(args.length) {
    int argi = 0, width, size;
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

        // type
        switch(*fmt) {
          case 'd':
            size = tsprintf_dec(args[0], buf, zeroflag, width);
            break;
          case 'x':
            size = tsprintf_hex(args[0], buf, zeroflag, width);
            break;
          case 'c':
            size = tsprintf_chr(cast(char)args[0], buf);
            break;
          case 's':
            size = tsprintf_str(cast(string)args[0], buf);
            break;
          default: // 謎フォーマットは無視
            *buf++ = *fmt;
            ++len;
        }

        buf += size;
        len += size;
        ++fmt;
      } else { // 普通の文字
        *buf++ = *fmt++;
        ++len;
      }
    }
  } else {
    while(*fmt) {
      *buf++ = *fmt++;
      ++len;
    }
  }
  *buf = '\0';
  return len;
}
// decimal
int tsprintf_dec(const long val,
                 char* buf,
                 const bool zeroflag,
                 int width) {
  int len=0;
  char[11] tmp; // 10ケタ+マイナス記号でintはカバーできる
  char* tmpp = &tmp[$-1]; // 後ろから
  long abs;
  bool minus = false;
  if(val == 0) {
    *tmpp-- = '0';
    ++len;
  } else {
    if(val < 0) {
      abs =~val+1; // signed
      minus = true;
    } else {
      abs = val;
    }
    while(abs) {
      *tmpp-- = abs % 10 + '0';
      abs /= 10;
      ++len;
    }
  }

  // 0のpaddingとマイナス記号
  if(zeroflag) {
    if(minus) --width; // 記号分
    while(len<width) {
      *tmpp-- = '0';
      ++len;
    }
    if(minus) {
      *tmpp-- = '-';
      ++len;
    }
  } else {
    if(minus) {
      *tmpp-- = '-';
      ++len;
    }
    while(len<width) {
      *tmpp-- = ' ';
      ++len;
    }
  }

  memcpy(buf, ++tmpp, len);
  return len;
}
// hexadecimal
int tsprintf_hex(ulong val,
                 char* buf,
                 const bool zeroflag,
                 const int width) {
  int len = 0;
  char[8] tmp;
  char* tmpp = &tmp[$-1];
  if(val == 0) {
    *tmpp-- = '0';
    ++len;
  } else {
    while(val) {
      *tmpp = val % 16;
      if(*tmpp < 10) {
        *tmpp += '0';
      } else {
        *tmpp += 'a' - 10;
      }
      val /= 16; // コンパイラが(>>=4とかに)最適化してくれる
      --tmpp;
      ++len;
    }
  }

  while(len < width) {
    *tmpp-- = zeroflag ? '0' : ' ';
    ++len;
  }

  memcpy(buf, ++tmpp, len);
  return len;
}
// char
int tsprintf_chr(const char c, char* buf) {
  *buf = c;
  return 1;
}
// string
int tsprintf_str(string str, char* buf) {
  memcpy(buf, cast(char*)str.ptr, str.length); // str.length+1までコピーする必要は無い
  return cast(int)str.length;
}

void memcpy(char* to_buf, char* from_buf, size_t n) {
  foreach(_; 0 .. n) *to_buf++=*from_buf++;
}
