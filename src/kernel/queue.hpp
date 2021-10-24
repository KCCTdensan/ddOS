template<typename T>
class ArrayQueue{
public:
  template<size_t N>
  ArrayQueue(std::array<T, N>& buf);
  ArrayQueue(T* buf, size_t size);
  kError Push(const T& value);
  kError pop();
  size_t Count() const;
  size_t Capacity() const;
  const T& Front() const;

private:
  T* data_;
  size_t read_pos_, write_pos_, count_;
  /*
   * read_pos_ points to an element to be read.
   * write_pos_ points to a blank position.
   * count_ is the number of element available.
   */
  const size_t capacity_;
};

template<typename T>
template<size_t N>
ArrayQueue<T>::ArrayQueue(std::array<T, N>& buf):ArrayQueue(buf.data(), N){}

template<typename T>
ArrayQueue<T>::ArrayQueue(T* buf, size_t size):data_{buf}, read_pos_{0}, write_pos_{0}, count_{0}, capacity_{size}{}

template<typename T>
kError ArrayQueue<T>::Push(const T& value){
  if(count_ == capacity_){
    return KernelError(kError::kFull);
  }

  data_[write_pos_] = value;
  ++count_;
  ++write_pos_;
  if(write_pos_ == capacity_){
    write_pos_ = 0;
  }
  return KernelError(kError::kSuccess);
}

template<typename T>
kError ArrayQueue<T>::pop(){
  if(count_ == 0){
    return KernelError(kError::kEmpty);
  }

  --count_;
  ++read_pos_;
  if(read_pos_ == capacity_){
    read_pos_ = 0;
  }
  return KernelError(kError::kSuccess);
}

template<typename T>
const T& ArrayQueue<T>::Front() const {
  return data_[read_pos_];
}

