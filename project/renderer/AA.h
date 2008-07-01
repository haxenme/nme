#ifndef RENDERER_AA_H

// --- AA traits classes ----------------------------------------------------

// The AA structures allow for the same code to be used for high-quality
//  and fast rendering.

struct AA1x
{
   enum { AABits = 0 };
   enum { AA = (1<<AABits) };

   typedef Uint8 State;
   static void InitState(State &outState)
      { outState = 0; }

   inline AA1x() : mVal(0) { }

   Uint8   mVal;

   void Debug() {}
   static inline int GetDVal(State &inState) { return 0; }

   static inline short SGetAlpha(State &inState)
      { return inState << 8; }

   static inline short GetAlpha(State &inState)
      { return (inState ^ 0x01) << 8; }

   int Value() const { return mVal; }

   inline void Transition(Uint8 &ioDrawing) const
   {
      ioDrawing ^=  mVal;
   }
   inline void Add(int inX,int inY)
   {
      mVal ^= 0x01;
   }
   inline void AddAA(int inX,int inY)
   {
      mVal ^= 0x01;
   }


};





struct AA4x
{
   enum { AABits = 2 };
   enum { AA = (1<<AABits) };
   typedef Uint8 State[4];

   inline AA4x() : mVal(0) { }

   union
   {
      Uint8 mPoints[4];
      int   mVal;
   };

   static void InitState(State &outState)
      { outState[0] = outState[1] = outState[2] = outState[3] = 0; }

   // This gets the value for alpha at at transition point
   inline short GetAlpha(Uint8 *inState) const // 8-bits fixed, [0,256] inclusive
   {
      return mAlpha[inState[0] | mPoints[0]] + 
             mAlpha[inState[1] | mPoints[1]] + 
             mAlpha[inState[2] | mPoints[2]] + 
             mAlpha[inState[3] | mPoints[3]];
   }
   inline int Value() const
   {
      return (mPoints[0]<< 12 ) |
             (mPoints[1]<< 8 ) |
             (mPoints[2]<< 4 ) |
             (mPoints[3]<< 0 );
   }

   static inline int GetDVal(State &inState)
   {
      return ( (inState[0]>>4) << 12) +
             ( (inState[1]>>4) << 8) +
             ( (inState[2]>>4) << 4) +
             ( (inState[3]>>4) << 0);
   }

   // This gets the value for alpha, which is constant for a given state
   //  (ie, no transtions going on at these points and depends only on state)
   //  The state will be 0x10 if the sub-row is begin drawn, 0 otherwise.
   static inline short SGetAlpha(Uint8 *inState)
   {
      return (inState[0] + inState[1] + inState[2] + inState[3]) << 2;
   }
   void Debug() { printf("<%x%x%x%x>", mPoints[0], mPoints[1], mPoints[2], mPoints[3]); }

   inline void Transition(Uint8 *ioDrawing) const
   {
      ioDrawing[0] = mDrawing[ioDrawing[0] | mPoints[0]];
      ioDrawing[1] = mDrawing[ioDrawing[1] | mPoints[1]];
      ioDrawing[2] = mDrawing[ioDrawing[2] | mPoints[2]];
      ioDrawing[3] = mDrawing[ioDrawing[3] | mPoints[3]];
   }
   // x is fixed-16, y is fixed-aa
   inline void Add(int inX,int inY)
   {
      mPoints[inY & 0x03] ^= (1 << ( (inX>>14) & 0x03));
   }

   // x is fixed-aa, y is fixed-aa
   inline void AddAA(int inX,int inY)
   {
      mPoints[inY & 0x03] ^= (1 << ( inX & 0x03));
   }



   static void Init()
   {
      static bool init = false;
      if (!init)
      {
         init = true;
         for(int i=0;i<32;i++)
         {
            int  sum = 0;
            bool draw = (i&0x10) != 0;
            if (i&0x01) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x02) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x04) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x08) draw = !draw;
            if (draw) sum+= 2;

            mDrawing[i] = draw ? 0x10 : 0;
            mAlpha[i] = (sum<<3); // 6-bit fixed, [0,64] inclusive
         }
      }
   }
   static bool   mIsInit;
   static Uint8  mDrawing[32];
   static int  mAlpha[32];
};


#endif
