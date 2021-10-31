module lib.string;

// tiny sprintf
int tsprintf(T ...)(char* buf, size_t buf_size, char* fmt, T args) {
  int len = 0;
  static if(args.length) {
    int width, size;
    bool zeroflag, formatted;
  }
  foreach(arg; args) {
    formatted = false;
    while(*fmt) {
      if(*fmt == '%') {
        width = 0;
        zeroflag = false;
        ++fmt;

        // length
        if(*fmt == '0') {
          zeroflag = true;
          ++fmt;
        }
        if(('0' <= *fmt) && (*fmt <= '9')) {
          width = *fmt++ - '0';
        }

        // type
        switch(*fmt) {
          case 'd':
            size = tsprintf_dec(arg, buf, zeroflag, width);
            formatted = true;
            break;
          case 'x':
            size = tsprintf_hex(arg, buf, zeroflag, width);
            formatted = true;
            break;
          case 'b':
            size = tsprintf_bin(arg, buf, zeroflag, width);
            formatted = true;
            break;
          case 'c':
            size = tsprintf_chr(cast(char)arg, buf);
            formatted = true;
            break;
          //case 's': // まあ要らんやろ (型エラーでコンパイルできない)
          //  size = tsprintf_str(cast(string)args[0], buf);
          //  break;
          default: // 謎フォーマットは無視
            *buf++ = *fmt;
            ++len;
        }

        buf += size;
        len += size;
        ++fmt;
        if(formatted) break;
      } else { // 普通の文字
        *buf++ = *fmt++;
        ++len;
      }
    }
  }
  while(*fmt) {
    *buf++ = *fmt++;
    ++len;
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
    if(width) {
      while(len < width && abs) {
        *tmpp-- = abs % 10 + '0';
        abs /= 10;
        ++len;
      }
    } else {
      while(abs) {
        *tmpp-- = abs % 10 + '0';
        abs /= 10;
        ++len;
      }
    }
  }

  // 0のpaddingとマイナス記号
  if(zeroflag) {
    if(minus) --width; // 記号分
    while(len < width) {
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
    while(len < width) {
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
    if(width) {
      while(len < width && val) {
        *tmpp = val % 16;
        val /= 16; // コンパイラが(>>=4とかに)最適化してくれる
        if(*tmpp < 10) {
          *tmpp += '0';
        } else {
          *tmpp += 'a' - 10;
        }
        --tmpp;
        ++len;
      }
    } else {
      while(val) {
        *tmpp = val % 16;
        val /= 16;
        if(*tmpp < 10) {
          *tmpp += '0';
        } else {
          *tmpp += 'a' - 10;
        }
        --tmpp;
        ++len;
      }
    }
  }

  while(len < width) {
    *tmpp-- = zeroflag ? '0' : ' ';
    ++len;
  }

  memcpy(buf, ++tmpp, len);
  return len;
}
// binary
int tsprintf_bin(ulong val,
                 char* buf,
                 const bool zeroflag,
                 const int width) {
  int len = 0,d16;
  char[8] tmp;
  char* tmpp = &tmp[$-1];
  if(val == 0) {
    *tmpp-- = '0';
    ++len;
  } else {
    if(width) {
      while(len < width && val) {
        d16 = val % 16;
        val /= 16;
        *tmpp-- = (d16 & 0b0001) ? '1' : '0';
        *tmpp-- = (d16 & 0b0010) ? '1' : '0';
        *tmpp-- = (d16 & 0b0100) ? '1' : '0';
        *tmpp-- = (d16 & 0b1000) ? '1' : '0';
        len+=4;
      }
    } else {
      while(val) {
        d16 = val % 16;
        val /= 16;
        *tmpp-- = (d16 & 0b0001) ? '1' : '0';
        *tmpp-- = (d16 & 0b0010) ? '1' : '0';
        *tmpp-- = (d16 & 0b0100) ? '1' : '0';
        *tmpp-- = (d16 & 0b1000) ? '1' : '0';
        len+=4;
      }
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
  foreach(i; 0 .. n) to_buf[i]=from_buf[i];
}
