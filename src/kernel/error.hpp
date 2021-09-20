#pragma once

#include <array>

class kError{
public:
  enum Code{
    kSuccess,
    EOC // End Of Code
  };
private:
  static constexpr std::array CodeNames{
    "kSuccess"
  };
  static_assert(kError::Code::EOC==CodeNames.size());

public:
  kError(Code code_) : code(code_){};
  const char* Name() const{
    return CodeNames[code];
  };
private:
  Code code;
};
