#include <Graphics.h>
#include <Surface.h>
#include "Render.h"

namespace nme
{

static bool IsPOW2(int inX)
{
   return (inX & (inX-1)) == 0;
}

enum { EDGE_CLAMP, EDGE_REPEAT, EDGE_POW2 };


#define GET_PIXEL_POINTERS \
         int frac_x = (mPos.x & 0xff00) >> 8; \
         int frac_nx = 0x100 - frac_x; \
         int frac_y = (mPos.y & 0xffff); \
         int frac_ny = 0x10000 - frac_y; \
 \
            if (EDGE == EDGE_CLAMP) \
            { \
               int x_step = 4; \
               int y_step = mStride; \
 \
               if (x<0) {  x_step = x = 0; } \
               else if (x>=mW1) { x_step = 0; x = mW1; } \
 \
               if (y<0) {  y_step = y = 0; } \
               else if (y>=mH1) { y_step = 0; y = mH1; } \
 \
               const uint8 * ptr = mBase + y*mStride + x*4; \
               p00 = *(ARGB *)ptr; \
               p01 = *(ARGB *)(ptr + x_step); \
               p10 = *(ARGB *)(ptr + y_step); \
               p11 = *(ARGB *)(ptr + y_step + x_step); \
            } \
            else if (EDGE==EDGE_POW2) \
            { \
               const uint8 *p = mBase + (y&mH1)*mStride; \
 \
               p00 = *(ARGB *)(p+ (x & mW1)*4); \
               p01 = *(ARGB *)(p+ ((x+1) & mW1)*4); \
 \
               p = mBase + ( (y+1) &mH1)*mStride; \
               p10 = *(ARGB *)(p+ (x & mW1)*4); \
               p11 = *(ARGB *)(p+ ((x+1) & mW1)*4); \
            } \
            else \
            { \
               int x1 = ((x+1) % mWidth) * 4; \
               if (x1<0) x1+=mWidth; \
               x = (x % mWidth)*4; \
               if (x<0) x+=mWidth; \
 \
               int y0= (y%mHeight); if (y0<0) y0+=mHeight; \
               const uint8 *p = mBase + y0*mStride; \
 \
               p00 = *(ARGB *)(p+ x); \
               p01 = *(ARGB *)(p+ x1); \
\
               int y1= ((y+1)%mHeight); if (y1<0) y1+=mHeight; \
               p = mBase + y1*mStride; \
               p10 = *(ARGB *)(p+ x); \
               p11 = *(ARGB *)(p+ x1); \
            }



#define MODIFY_EDGE_XY \
         if (EDGE == EDGE_CLAMP) \
         { \
            if (x<0) x = 0; \
            else if (x>=mWidth) x = mW1; \
 \
            if (y<0) y = 0; \
            else if (y>=mHeight) y = mH1; \
         } \
         else if (EDGE == EDGE_POW2) \
         { \
            x &= mW1; \
            y &= mH1; \
         } \
         else if (EDGE == EDGE_REPEAT) \
         { \
            x = x % mWidth; \
            y = y % mHeight; \
         }





class BitmapFillerBase : public Filler
{
public:
	BitmapFillerBase(GraphicsBitmapFill *inFill) : mBitmap(inFill)
	{
		mWidth = mBitmap->bitmapData->Width();
		mHeight = mBitmap->bitmapData->Height();
		mW1 = mWidth-1;
		mH1 = mHeight-1;
		mBase = mBitmap->bitmapData->GetBase();
		mStride = mBitmap->bitmapData->GetStride();
	}

   inline void SetPos(int inSX,int inSY)
	{
		mPos.x = (int)( (mMapper.m00*inSX + mMapper.m01*inSY + mMapper.mtx) * (1<<16) + 0.5);
		mPos.y = (int)( (mMapper.m10*inSX + mMapper.m11*inSY + mMapper.mty) * (1<<16) + 0.5);
	}

   void SetupMatrix(const Matrix &inMatrix)
	{
		// Get combined mapping matrix...
		Matrix mapper = inMatrix;
		mapper = mapper.Mult(mBitmap->matrix);
		mMapper = mapper.Inverse();
		//mMapper.Scale(mWidth/1638.4,mHeight/1638.4);
		mMapper.Translate(0.5,0.5);

		mDPxDX = (int)(mMapper.m00 * (1<<16)+ 0.5);
		mDPyDX = (int)(mMapper.m10 * (1<<16)+ 0.5);
	}


	const uint8 *mBase;
	int  mStride;

	ImagePoint mPos;
	int mDPxDX;
	int mDPyDX;
	int mWidth;
	int mHeight;
	int mW1;
	int mH1;
	Matrix mMapper;
	GraphicsBitmapFill *mBitmap;
};


template<int EDGE,bool SMOOTH,bool HAS_ALPHA>
class BitmapFiller : public BitmapFillerBase
{
public:
	BitmapFiller(GraphicsBitmapFill *inFill) : BitmapFillerBase(inFill) { }

   ARGB GetInc( )
	{
		int x = mPos.x >> 16;
      int y = mPos.y >> 16;
		if (SMOOTH)
		{
         ARGB result;

         ARGB p00,p01,p10,p11;

         GET_PIXEL_POINTERS

		   mPos.x += mDPxDX;
		   mPos.y += mDPyDX;

         result.c0 = ( (p00.c0*frac_nx + p01.c0*frac_x)*frac_ny +
                    (  p10.c0*frac_nx + p11.c0*frac_x)*frac_y ) >> 24;
         result.c1 = ( (p00.c1*frac_nx + p01.c1*frac_x)*frac_ny +
                    (  p10.c1*frac_nx + p11.c1*frac_x)*frac_y ) >> 24;
         result.c2 = ( (p00.c2*frac_nx + p01.c2*frac_x)*frac_ny +
                    (  p10.c2*frac_nx + p11.c2*frac_x)*frac_y ) >> 24;

         if (HAS_ALPHA)
         {
            result.a = ( (p00.a*frac_nx + p01.a*frac_x)*frac_ny +
                         (p10.a*frac_nx + p11.a*frac_x)*frac_y ) >> 24;
         }
			else
            result.a = 255;
         return result;
      }
      else
      {
		   mPos.x += mDPxDX;
		   mPos.y += mDPyDX;
         MODIFY_EDGE_XY;
         return *(ARGB *)( mBase + y*mStride + x*4);
      }
	}

   void Fill(const AlphaMask &mAlphaMask,int inTX,int inTY,
       const RenderTarget &inTarget,const RenderState &inState)
	{
		SetupMatrix(*inState.mTransform.mMatrix);

		bool swap =  (inTarget.mPixelFormat & pfSwapRB) != (mBitmap->bitmapData->Format() & pfSwapRB);
		Render( mAlphaMask, *this, inTarget, swap, inState, inTX,inTY );
	}

};


// --- Pseudo constructor ---------------------------------------------------------------

template<int EDGE,bool SMOOTH>
static Filler *CreateAlpha(GraphicsBitmapFill *inFill)
{
	if (inFill->bitmapData->Format() & pfHasAlpha)
	   return new BitmapFiller<EDGE,SMOOTH,true>(inFill);
	else
	   return new BitmapFiller<EDGE,SMOOTH,false>(inFill);
}


template<int EDGE>
static Filler *CreateEdge(GraphicsBitmapFill *inFill)
{
	if (inFill->smooth)
	   return CreateAlpha<EDGE,true>(inFill);
	else
	   return CreateAlpha<EDGE,false>(inFill);
}

Filler *Filler::Create(GraphicsBitmapFill *inFill)
{
	if (inFill->repeat)
	{
		if ( IsPOW2(inFill->bitmapData->Width()) && IsPOW2(inFill->bitmapData->Height()) )
		   return CreateEdge<EDGE_POW2>(inFill);
		else
		   return CreateEdge<EDGE_REPEAT>(inFill);
	}
	else
		return CreateEdge<EDGE_CLAMP>(inFill);
}


} // end namespace nme

