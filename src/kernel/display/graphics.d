import fb_conf;

// Pixel Writer

struct RGBColor {
  ubyte r,g,b;
}
//extern(C++)
//alias PixelColor = RGBColor;

class PixelWriter {
public:
  this(const FBConf fbc) { this.fbconf = fbc; }
  abstract void Write(const uint x, const uint y, const RGBColor c);
protected:
  const ubyte* PixelAt(uint x, uint y) {
    return cast(ubyte*) fbconf.buf + 4 * (fbconf.pixels_per_line * y + x);
  }
private:
  const FBConf fbconf;
}

class PixelWriterRGB : PixelWriter {
public:
  this(const FBConf fbc) {
    super(fbc);
  }
  override void Write(const uint x, const uint y, const RGBColor c) {
    auto p = PixelAt(x,y);
    p[0] = c.r;
    p[1] = c.g;
    p[2] = c.b;
  }
}

class PixelWriterBGR : PixelWriter {
public:
  this(const FBConf fbc) {
    super(fbc);
  }
  override void Write(const uint x, const uint y, const RGBColor c) {
    auto p = PixelAt(x,y);
    p[0] = c.b;
    p[1] = c.g;
    p[2] = c.r;
  }
}

// お便利ツールズ

class Vector2D(T) {
  public:
  this(T x_,T y_) {
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

void FillRectangle(ref PixelWriter writer,
                   ref const Vector2D!uint start,
                   ref const Vector2D!uint size,
                   ref const RGBColor c) {
  for(int dy=0;dy<size.y;++dy)
    for(int dx=0;dx<size.x;++dx)
      writer.Write(start.x+dx,start.y+dy,c);
}
