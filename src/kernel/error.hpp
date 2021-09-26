#pragma once

#include <array>

class kError {
public:
  enum Code {
    kSuccess,
    kFull,
    kEmpty,
    kNoEnoughMemory,
    kIndexOutOfRange,
    kHostControllerNotHalted,
    kInvalidSlotID,
    kPortNotConnected,
    kInvalidEndpointNumber,
    kTransferRingNotSet,
    kAlreadyAllocated,
    kNotImplemented,
    kInvalidDescriptor,
    kBufferTooSmall,
    kUnknownDevice,
    kNoCorrespondingSetupStage,
    kTransferFailed,
    kInvalidPhase,
    kUnknownXHCISpeedID,
    kNoWaiter,
    kNoPCIMSI,
    kUnknownPixelFormat,
    kNoSuchTask,
    kInvalidFormat,
    kFrameTooSmall,
    kInvalidFile,
    kIsDirectory,
    kNoSuchEntry,
    kFreeTypeError,
    kEndpointNotInCharge,
    EOC // End Of Codes
  };
private:
  static constexpr std::array CodeNames {
    "kSuccess",
    "kFull",
    "kEmpty",
    "kNoEnoughMemory",
    "kIndexOutOfRange",
    "kHostControllerNotHalted",
    "kInvalidSlotID",
    "kPortNotConnected",
    "kInvalidEndpointNumber",
    "kTransferRingNotSet",
    "kAlreadyAllocated",
    "kNotImplemented",
    "kInvalidDescriptor",
    "kBufferTooSmall",
    "kUnknownDevice",
    "kNoCorrespondingSetupStage",
    "kTransferFailed",
    "kInvalidPhase",
    "kUnknownXHCISpeedID",
    "kNoWaiter",
    "kNoPCIMSI",
    "kUnknownPixelFormat",
    "kNoSuchTask",
    "kInvalidFormat",
    "kFrameTooSmall",
    "kInvalidFile",
    "kIsDirectory",
    "kNoSuchEntry",
    "kFreeTypeError",
    "kEndpointNotInCharge",
  };
  static_assert(Code::EOC==CodeNames.size());

public:
  // kError(Code code_,const char* file_,int line_)
  //   : code(code_),file(file_),line(line_){};
  kError(Code code_) : code(code_){};

  Code Cause() const {
    return this->code;
  }
  const char* Name() const {
    return CodeNames[code];
  }

  operator bool() const {
    return this->code!=kSuccess;
  }
private:
  Code code;
  const char* file;
  int line;
};

template<class T>
struct WithError {
  T data;
  kError error;
};

// std::source_locationが使えるようになるまで我慢
// #define MAKE_ERROR(code) Error((code), __FILE__, __LINE__)
inline kError KernelError(kError::Code code_){
  return kError(code_);
}
