// fb_conf.hpp
enum PixelFmt{
  kPixelRGB,
  kPixelBGR
}
struct FBConf{
  ubyte* buf;
  uint pixels_per_line;
  uint res_horiz;
  uint res_vert;
  PixelFmt pixel_fmt;
}
// fb_conf.hpp

// Pixel Writer

struct RGBColor {
  ubyte r,g,b;
}
extern(C++)
alias PixelColor = RGBColor;

extern(C++)
class PixelWriter {
public:
  this(const FBConf fbc) { this.fbconf = fbc; }
  abstract void Write(uint x, uint y, ref const PixelColor c);
protected:
  ubyte* PixelAt(uint x, uint y) {
    return fbconf.buf+4*(fbconf.pixels_per_line*y+x);
  }
private:
  const FBConf fbconf;
}

extern(C++)
class PixelWriterRGB : PixelWriter {
public:
  this(const FBConf fbc){
    super(fbc);
  }
  override void Write(uint x, uint y, ref const PixelColor c) {
    auto p = PixelAt(x,y);
    p[0] = c.r;
    p[1] = c.g;
    p[2] = c.b;
  }
}

extern(C++)
class PixelWriterBGR : PixelWriter {
public:
  this(const FBConf fbc){
    super(fbc);
  }
  override void Write(uint x, uint y, ref const PixelColor c) {
    auto p = PixelAt(x,y);
    p[0] = c.b;
    p[1] = c.g;
    p[2] = c.r;
  }
}

// お便利ツールズ

extern(C++)
class Vector2D(T) {
  public:
  this(T x_,T y_) {
    this.x = x_;
    this.y = y_;
  }

  T x,y;

  Vector2D!T opOpAssign(string op)(const T d) const if(op == "+") {
    this.x += d.x;
    this.y += d.y;
    return this;
  }
}

extern(C++)
void FillRectangle(ref PixelWriter writer,
                   ref const Vector2D!uint start,
                   ref const Vector2D!uint size,
                   ref const PixelColor c) {
  for(int dy=0;dy<size.y;++dy)
    for(int dx=0;dx<size.x;++dx)
      writer.Write(start.x+dx,start.y+dy,c);
}
