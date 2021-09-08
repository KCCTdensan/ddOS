#pragma once

#include "fb_conf.hpp"

struct PixelColor{
  uint8_t r,g,b;
};

class PixelWriter{
public:
  PixelWriter(const FBConf& conf) : fbconf(conf){};
  virtual ~PixelWriter() = default;
  virtual void Write(int,int,const PixelColor&) = 0;
protected:
  uint8_t* PixelAt(int,int);
private:
  const FBConf& fbconf;
};

class PixelWriterRGB : public PixelWriter{
public:
  using PixelWriter::PixelWriter;
  virtual void Write(int,int,const PixelColor&) override;
};

class PixelWriterBGR : public PixelWriter{
public:
  using PixelWriter::PixelWriter;
  virtual void Write(int,int,const PixelColor&) override;
};
