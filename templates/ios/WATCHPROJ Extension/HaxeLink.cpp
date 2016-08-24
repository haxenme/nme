#include <stdio.h>
#include "HaxeLink.h"

static HxHaxeCall callback = 0;
static bool isBooted = 0;
   

namespace hx
{
   void PushTopOfStack(void *);
   void PopTopOfStack();
};

extern "C" const char *hxRunLibrary();

class HaxeAttach
{
   bool isAttached;
   public:
      HaxeAttach(bool inAttach=true)
      {
         isAttached = false;
         if (inAttach)
            attach();
      }
      ~HaxeAttach()
      {
         detach();
      }
      inline void attach()
      {
         if (!isAttached)
         {
            isAttached = true;
            hx::PushTopOfStack(this);
         }
      }
      inline void detach()
      {
         if (isAttached)
         {
            isAttached = false;
            hx::PopTopOfStack();
         }
      }
};




void HxSetHaxeCallback(HxHaxeCall inCallback )
{
   callback = inCallback;
}

void HxBoot()
{
   if (!isBooted)
   {
      isBooted = true;
      HaxeAttach attach;

      const char *err = hxRunLibrary();
      if (err)
         printf(" Error %s\n", err );
   }
}


int HxCall(int inFunction,int inIParam, double inDParam, void *inPtrParam)
{
   HxBoot();

   if (callback)
   {
      HaxeAttach attach;
      return callback(inFunction, inIParam, inDParam, inPtrParam);
   }

   return 0;
}



