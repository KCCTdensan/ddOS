import fb_conf;

// Pixel Writer

struct RGBColor {
  ubyte r,g,b;
}

// ほんとはクラスとか(vtableとか)使いたいんだけどなー
struct PixelWriter {
  this(const FBConf fbc) {
    this.fbconf = fbc;
    final switch(fbc.pixel_fmt) {
      case PixelFmt.kPixelRGB:
        this.write = &PixelWriteRGB;
        break;
      case PixelFmt.kPixelBGR:
        this.write = &PixelWriteBGR;
        break;
    }
  }
  //abstract void Write(const uint x, const uint y, const RGBColor c); // class使わせろ
  void delegate(const uint x, const uint y, const RGBColor c) write;

private: // モジュール内ならアクセスできるというガバガバ
  const ubyte* PixelAt(uint x, uint y) { // 本来はprotectedなメソッド
    return cast(ubyte*)/*なぜ？*/ fbconf.buf + 4/*sizeof a pixel*/ * (fbconf.pixels_per_line * y + x);
  }
  void PixelWriteRGB(const uint x, const uint y, const RGBColor c) {
    auto/*ubyte[4]くらいに解釈してほしい*/ p = PixelAt(x, y);
    p[0] = c.r;
    p[1] = c.g;
    p[2] = c.b;
  };
  void PixelWriteBGR(const uint x, const uint y, const RGBColor c) {
    auto p = PixelAt(x, y);
    p[0] = c.b;
    p[1] = c.g;
    p[2] = c.r;
  };

  const FBConf fbconf;
}

// お便利ツールズ

struct Vector2D(T) {
  this(T x_, T y_) {
    this.x = x_;
    this.y = y_;
  }

  T x,y;

  ref Vector2D opOpAssign(string op)(Vector2D d) if(op == "+") {
    this.x += d.x;
    this.y += d.y;
    return this;
  }
}

void FillRectangle(const PixelWriter* writer,
                   const Vector2D!uint start,
                   const Vector2D!uint size,
                   const RGBColor c) {
  foreach(dy; 0 .. size.y)
    foreach(dx; 0 .. size.x)
      writer.write(start.x + dx, start.y + dy, c);
}
