#include <errno.h>
#include <sys/types.h>

// sprintf用
caddr_t sbrk(int incr){
  errno=ENOMEM;
  return (caddr_t)-1;
}
