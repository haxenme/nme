#ifndef NME_QUICK_VEC
#define NME_QUICK_VEC

#include <algorithm>
#include <memory.h>
#include <stdlib.h>
#include <stdexcept>

namespace nme
{

template<typename T>
void DoDelete(T &item)
{
}

template<typename T>
void DoDelete(T *&item)
{
   delete item;
   item = 0;
}



// Little vector/set class, optimised for small data and not using many malloc calls.
// Data are allocated with "malloc", so they should not rely on constructors etc.
template<typename T_,int QBUF_SIZE_=16>
class QuickVec
{
   enum { QBufSize = QBUF_SIZE_ };
public:
   typedef T_ *iterator;
   typedef const T_ * const_iterator;

public:
   QuickVec()
   {
      mPtr = QBUF_SIZE_==0 ? 0 : mQBuf;
      mAlloc = QBufSize;
      mSize = 0;
   }
   QuickVec(const QuickVec<T_,QBUF_SIZE_> &inRHS)
   {
      if (QBUF_SIZE_!=0 && inRHS.mSize<=QBufSize)
      {
         mAlloc = QBufSize;
         mPtr = mQBuf;
      }
      else
      {
         mAlloc = inRHS.mAlloc;
         mPtr = (T_ *)malloc(mAlloc * sizeof(T_));
      }
      mSize = inRHS.mSize;
      memcpy(mPtr,inRHS.mPtr,sizeof(T_)*mSize);
   }
   size_t Mem() const { return mAlloc * sizeof(T_); }
   QuickVec(const T_ *inData,size_t inLen)
   {
      mPtr = QBUF_SIZE_==0 ? 0 : mQBuf;
      mAlloc = QBufSize;
      mSize = 0;

      resize(inLen);
      memcpy(mPtr,inData,sizeof(T_)*inLen);
   }
   QuickVec(size_t inLen)
   {
      mPtr = QBUF_SIZE_==0 ? 0 : mQBuf;
      mAlloc = QBufSize;
      mSize = 0;

      resize(inLen);
   }
   ~QuickVec()
   {
      if (QBUF_SIZE_==0 || mPtr!=mQBuf)
         if (mPtr)
            free(mPtr);
   }
   void clear()
   {
      if (QBUF_SIZE_==0)
      {
         if (mPtr)
            free(mPtr);
         mPtr = 0;
         mAlloc = 0;
      }
      else if (mPtr!=mQBuf)
      {
         free(mPtr);
         mPtr = mQBuf;
         mAlloc = QBufSize;
      }
      mSize = 0;
   }

   void Set(const T_ *inData,size_t inN)
   {
      resize(inN);
      if (inN)
         memcpy(mPtr,inData,inN*sizeof(T_));
   }
   void Zero()
   {
      if (mPtr && mSize)
         memset(mPtr,0,mSize*sizeof(T_));
   }

   // This assumes the values in the array are sorted.
   template<typename X_, typename D_>
   void Change(X_ inValue,D_ inDiff)
   {
      if (mSize==0)
      {
         mPtr[mSize++] = T_(inValue,inDiff);
         return;
      }

      // Before/at start
      if (mPtr[0]==inValue)
      {
         mPtr[0] += inDiff;
      }
      else if (mPtr[0]>inValue)
      {
         InsertAt(0, T_(inValue,inDiff) );
      }
      else
      {
         size_t last = mSize-1;
         // After/on end
         if (mPtr[last]==inValue)
         {
            mPtr[last] += inDiff;
         }
         else if (mPtr[last]<inValue)
         {
            Grow();
            mPtr[mSize] = T_(inValue,inDiff);
            ++mSize;
         }
         else
         {
            // between 0 ... last
            size_t min = 0;
            size_t max = last;

            while(max>min+1)
            {
               size_t middle = (max+min+1)/2;
               T_ &v = mPtr[middle];
               if (v==inValue)
               {
                  v += inDiff;
                  return;
               }
               if (v<inValue)
                  min = middle;
               else
                  max = middle;
            }
            // Not found, must be between min and max (=min+1)
            InsertAt(min+1,T_(inValue,inDiff) );
         }
      }
   }


   // This assumes the values in the array are sorted.
   void Toggle(T_ inValue)
   {
      if (mSize==0)
      {
         mPtr[mSize++] = inValue;
         return;
      }

      // Before/at start
      if (inValue<=mPtr[0])
      {
         if (inValue==mPtr[0])
            EraseAt(0);
         else
            InsertAt(0,inValue);
      }
      else
      {
         size_t last = mSize-1;
         // After/on end
         if (inValue>=mPtr[last])
         {
            if (inValue==mPtr[last])
               EraseAt(last);
            else
            {
               Grow();
               mPtr[mSize] = inValue;
               ++mSize;
            }
         }
         else
         {
            // between 0 ... last
            size_t min = 0;
            size_t max = last;

            while(max>min+1)
            {
               size_t middle = (max+min+1)/2;
               T_ v = mPtr[middle];
               if (v==inValue)
               {
                  EraseAt(middle);
                  return;
               }
               if (v<inValue)
                  min = middle;
               else
                  max = middle;
            }
            // Not found, must be between min and max (=min+1)
            InsertAt(min+1,inValue);
         }
      }
   }

   inline void Grow()
   {
      if (mSize>=mAlloc)
      {
         if (QBUF_SIZE_!=0 && mPtr==mQBuf)
         {
            mPtr = (T_ *)malloc(sizeof(T_)*(QBufSize*2));
            memcpy(mPtr, mQBuf, sizeof(mQBuf));
            mAlloc = QBufSize*2;
         }
         else
         {
            if (mAlloc)
               mAlloc *= 2;
            else
               mAlloc = 16;
            mPtr = (T_*)realloc(mPtr, sizeof(T_)*mAlloc);
         }
      }
   }
   void reserve(size_t inSize)
   {
      if (mAlloc<inSize && (QBUF_SIZE_==0 || inSize>QBufSize) )
      {
         mAlloc = inSize;

         if (QBUF_SIZE_==0 || mPtr!=mQBuf)
         {
            mPtr = (T_ *)realloc(mPtr,sizeof(T_)*mAlloc);
         }
         else
         {
            T_ *buf = (T_ *)malloc(sizeof(T_)*mAlloc);
            memcpy(buf,mPtr,mSize*sizeof(T_));
            mPtr = buf;
         }
      }
   }

   void resizeSpace(size_t inSize)
   {
      if (mAlloc<inSize)
      {
         if (QBUF_SIZE_!=0 && mPtr==mQBuf)
         {
            mAlloc = inSize*3/2;
            mPtr = (T_ *)malloc(sizeof(T_)*(mAlloc));
            memcpy(mPtr, mQBuf, sizeof(T_)*mSize);
         }
         else
         {
            mAlloc = inSize*3/2;
            mPtr = (T_*)realloc(mPtr, sizeof(T_)*mAlloc);
         }

      }
      mSize = inSize;
   }


   void resize(size_t inSize)
   {
      if (mAlloc<inSize)
      {
         if (QBUF_SIZE_!=0 && mPtr==mQBuf)
         {
            mAlloc = inSize;
            mPtr = (T_ *)malloc(sizeof(T_)*(mAlloc));
            memcpy(mPtr, mQBuf, sizeof(T_)*mSize);
         }
         else
         {
            mAlloc = inSize;
            mPtr = (T_*)realloc(mPtr, sizeof(T_)*mAlloc);
         }

      }
      mSize = inSize;
   }

   inline void qpush(const T_ &inVal)
   {
      mPtr[mSize++] = inVal;
   }

   inline void push_back(const T_ &inVal)
   {
      Grow();
      mPtr[mSize++] = inVal;
   }
   inline T_ qpop()
   {
      return mPtr[--mSize];
   }

   template<typename RHS_>
   inline void qremove(const RHS_ &value)
   {
      for(size_t i=0;i<mSize;i++)
         if (mPtr[i]==value)
         {
            mPtr[i] = mPtr[--mSize];
            return;
         }
   }

   inline void qremoveAt(size_t inIndex)
   {
      mPtr[inIndex] = mPtr[--mSize];
   }

 
   inline void EraseAt(size_t inPos)
   {
      memmove(mPtr + inPos, mPtr + inPos + 1, (mSize-inPos-1) * sizeof(T_) );
      --mSize;
   }
   inline void EraseAt(size_t inFirst,size_t inLast)
   {
      memmove(mPtr + inFirst, mPtr + inLast, (mSize-inLast) * sizeof(T_) );
      mSize -= inLast-inFirst;
   }
   void erase(size_t inFirst,size_t inLen)
   {
      if (inFirst>mSize || inFirst<0)
      {
         throw std::runtime_error("bad erase");
      }
      if (inFirst+inLen>=mSize || inLen<0)
         resize(inFirst);
      else
      {
         memmove(mPtr + inFirst, mPtr + inFirst + inLen, (mSize-inFirst-inLen) * sizeof(T_) );
         mSize -= inLen;
      }
   }

   inline void InsertAt(size_t inPos,const T_ &inValue)
   {
      Grow();
      memmove(mPtr + inPos + 1, mPtr + inPos, (mSize-inPos) * sizeof(T_) );
      memcpy(mPtr+inPos,&inValue, sizeof(T_));
      ++mSize;
   }

   inline void InsertAt(size_t inPos,const T_ *inValues,size_t inN)
   {
      resize(mSize+inN);
      memmove(mPtr + inPos + inN, mPtr + inPos, (mSize-inPos-inN) * sizeof(T_) );
      memcpy(mPtr+inPos,inValues,inN*sizeof(T_));
   }

   inline size_t ByteCount() const { return mSize*sizeof(T_); }
   inline unsigned char *ByteData() { return (unsigned char *)mPtr; }
   inline const unsigned char *ByteData() const { return (const unsigned char *)mPtr; }
   
   bool operator == (const QuickVec<T_,QBUF_SIZE_> &inRHS) { return (*mPtr == *(inRHS.mPtr)); }
   bool operator != (const QuickVec<T_,QBUF_SIZE_> &inRHS) { return !(*mPtr == *(inRHS.mPtr)); }

   inline size_t size() const { return mSize; }
   inline bool empty() const { return mSize==0; }
   inline T_& operator[](size_t inIndex) { return mPtr[inIndex]; }
   inline T_& last() { return mPtr[mSize-1]; }
   inline const T_& operator[](size_t inIndex) const { return mPtr[inIndex]; }
   inline iterator begin() { return mPtr; }
   inline iterator rbegin() { return mPtr + mSize -1; }
   inline iterator end() { return mPtr + mSize; }
   inline const_iterator begin() const { return mPtr; }
   inline const_iterator rbegin() const { return mPtr + mSize - 1; }
   inline const_iterator end() const { return mPtr + mSize; }
   void swap( QuickVec<T_,QBUF_SIZE_> &inRHS )
   {
      if (QBUF_SIZE_==0)
      {
         std::swap(mPtr,inRHS.mPtr);
      }
      else if (mPtr!=mQBuf)
      {
         // Both "real" pointers - just swap them
         if (inRHS.mPtr!=inRHS.mQBuf)
         {
            std::swap(mPtr,inRHS.mPtr);
         }
         else
         {
            // RHS in in the qbuf, we have a pointer
            memcpy(mQBuf,inRHS.mQBuf,inRHS.mSize*sizeof(T_));
            inRHS.mPtr = mPtr;
            mPtr = mQBuf;
         }
      }
      else
      {
         // We have a qbuf, rhs has a pointer
         if (inRHS.mPtr!=inRHS.mQBuf)
         {
            memcpy(inRHS.mQBuf,mQBuf,mSize*sizeof(T_));
            mPtr = inRHS.mPtr;
            inRHS.mPtr = inRHS.mQBuf;
         }
         else
         {
            // Both using QBuf ...
            if (mSize && inRHS.mSize)
            {
               T_ tmp[QBufSize];
               memcpy(tmp,mPtr,mSize*sizeof(T_));
               memcpy(mPtr,inRHS.mPtr,inRHS.mSize*sizeof(T_));
               memcpy(inRHS.mPtr,tmp,mSize*sizeof(T_));
            }
            else if (mSize)
               memcpy(inRHS.mQBuf,mQBuf,mSize*sizeof(T_));
            else
               memcpy(mQBuf,inRHS.mQBuf,inRHS.mSize*sizeof(T_));
         }
      }

      std::swap(mAlloc,inRHS.mAlloc);
      std::swap(mSize,inRHS.mSize);
   }

   QuickVec<T_,QBUF_SIZE_> &operator=(const QuickVec<T_,QBUF_SIZE_> &inRHS)
   {
      if ( (QBUF_SIZE_==0 || mPtr!=mQBuf) && mPtr )
         free(mPtr);

      if (QBUF_SIZE_!=0 && inRHS.mSize<=QBufSize)
      {
         mPtr = mQBuf;
         mAlloc = QBufSize;
      }
      else
      {
         mAlloc = inRHS.mAlloc;
         mPtr = (T_ *)(mAlloc ? malloc( mAlloc * sizeof(T_)) : 0);
      }
      mSize = inRHS.mSize;
      if (mSize)
         memcpy(mPtr,inRHS.mPtr,mSize*sizeof(T_));
      return *this;
   }
   void DeleteAll()
   {
      for(size_t i=0;i<mSize;i++)
         DoDelete( mPtr[i] );
      resize(0);
   }

   void append(const QuickVec<T_> &inOther)
   {
      size_t s = mSize;
      resize(mSize+inOther.mSize);
      for(size_t i=0;i<inOther.mSize;i++)
         mPtr[s+i] = inOther[i];
   }
   void append(const T_ *inOther,size_t inLen)
   {
      size_t s = mSize;
      resize(mSize+inLen);
      for(size_t i=0;i<inLen;i++)
         mPtr[s+i] = inOther[i];
   }

   // bool verify() { return mSize<=mAlloc; }

   T_  *mPtr;
   T_  mQBuf[QBufSize==0?1:QBufSize];
   size_t mAlloc;
   size_t mSize;

};

} // end namespace nme

#endif
