class KError {
  public enum Code {
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
  }
  private string[] codestr = [
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
  ];
public:
  this(Code code_, string file_, int line_) {
    code = code_;
    file = file_;
    line = line_;
  }

  string Name() const {
    return codestr[code];
  }
  Code Cause() const {
    return this.code;
  }
  string File() const {
    return this.file;
  }
  int Line() const {
    return this.line;
  }

private:
  const Code code;
  const string file;
  const int line;
}

bool opCast(T: bool)(KError e) const {
  return e.code != KError.Code.kSuccess;
}

unittest {
  assert(Code.EOC == CodeNames.length);
}

extern(C++)
struct WithError(T) {
  this(KError e, T d) { data = d; error = e; }
  T data;
  KError error;
}

KError KernelError(KError.Code code_,
                   string file = __FILE__,
                   int line = __LINE__) {
  return KError(code_, __FILE__, __LINE__);
}

/* from hpp
  static_assert(Code::EOC==CodeNames.size());

public:
  // kError(Code code_,const char* file_,int line_)
  //   : code(code_),file(file_),line(line_){};
  kError(Code code_) : code(code_){};

  const char* Name() const {
    return CodeNames[code];
  }

  Code Cause() const {
    return this->code;
  }
  const char* File() const {
    return this->file;
  }
  int Line() const {
    return this->line;
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
*/