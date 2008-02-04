#ifndef BYTE_ARRAY_H
#define BYTE_ARRAY_H

#include<string>
#include <neko.h>

DECLARE_KIND( k_byte_array );
#define BYTEARRAY(v) ( (ByteArray *)(val_data(v)) )

class ByteArray
{
   typedef unsigned char uint8;
public:
   ByteArray(int inSize=0)
   {
      mAlloc = inSize;
      mSize = inSize;
      mPtr = new uint8[inSize];
   }
   value ToValue();


   ~ByteArray()
   {
      delete [] mPtr;
   }
   inline void MakeSpace(int inS)
   {
      if (mAlloc<inS)
      {
         mAlloc = mAlloc*3/2+20;
         uint8 *ptr = new uint8[mAlloc];
         if (mPtr)
         {
            memcpy(ptr,mPtr,mSize);
            delete mPtr;
         }
         memset(ptr+mSize,0,mAlloc-mSize);
         mPtr = ptr;
      }
   }
   inline void set(int inI,int inVal)
   {
      int s = inI+1;
      MakeSpace(s);
      mPtr[inI] = inVal;
      if (mSize<s)
         mSize = s;

   }
   inline void push(int inI)
   {
      int s = mSize + 1;
      MakeSpace(s);
      mPtr[mSize] = inI;
      mSize = s;
   }

   uint8 *mPtr;
   int   mAlloc;
   int   mSize;

private: // Hide - not implemented
   ByteArray(const ByteArray &inRHS);
   void operator=(const ByteArray &inRHS);
};


#endif
