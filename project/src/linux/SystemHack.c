#define __fdelt_chk __fdelt_chk_local
#include <sys/select.h>
#undef __fdelt_chk

// Some linux variations use "unsigned int" and some don't have it
//  int the dlls.  So force it here.
long int __fdelt_chk (long int d)
{
  if (d >= FD_SETSIZE)
  {
     //printf("Select - bad fd.\n");
     return 0;
  }

  return d / __NFDBITS;
}

