template<typename T>
class ArrayQueue{
public:
  template<size_t N>
  ArrayQueue(std::array<T, N>& buf);
  ArrayQueue(T* buf, size_t size);
  Error Push(const T& value);
  Error pop();
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