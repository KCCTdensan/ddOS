#pragma once

#include "fb_conf.hpp"

struct PixelColor{
  uint8_t r,g,b;
};

class PixelWriter{
public:
  PixelWriter(const FBConf& conf) : fbconf(conf){}
  virtual ~PixelWriter()=default;
  virtual void Write(unsigned int x,
                     unsigned int y,
                     const PixelColor& c)=0;
protected:
  uint8_t* PixelAt(unsigned int,unsigned int);
private:
  const FBConf& fbconf;
};

class PixelWriterRGB : public PixelWriter{
public:
  using PixelWriter::PixelWriter;
  virtual void Write(unsigned int,unsigned int,
                     const PixelColor&) override;
};

class PixelWriterBGR : public PixelWriter{
public:
  using PixelWriter::PixelWriter;
  virtual void Write(unsigned int,unsigned int,
                     const PixelColor&) override;
};

template<typename T>
class Vector2D{
public:
  Vector2D(T x_,T y_) : x(x_),y(y_){}
  ~Vector2D()=default;

  T x,y;

  template<typename U>
  Vector2D<T>& operator +=(const Vector2D<U>& d){
    x+=d.x;
    y+=d.y;
    return *this;
  }
};

void FillRectangle(PixelWriter& writer,
                   const Vector2D<unsigned int>& start,
                   const Vector2D<unsigned int>& size,
                   const PixelColor& c);
