#ifndef ALPHA_RUNS_H
#define ALPHA_RUNS_H

#include "QuickVec.h"
#include <vector>


struct AlphaRun
{
   inline AlphaRun() { }
   inline AlphaRun(int inX0,int inX1,short inAlpha) : mX0(inX0), mX1(inX1), mAlpha(inAlpha) { }
   inline bool Contains(int inX) const { return inX >= mX0 && inX<mX1; }
   inline void Set(int inX0,int inX1,int inAlpha)
      { mX0 = inX0; mX1 = inX1; mAlpha = inAlpha; }

   short mX0,mX1;
   // mAlpha is 0 ... 256 inclusive
   short mAlpha;
};


typedef QuickVec<AlphaRun> AlphaRuns;
typedef std::vector<AlphaRuns> Lines;



#endif
