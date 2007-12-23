#include "Pixel.h"
#include <algorithm>



template<int MODE_,typename DEST_,typename SRC_>
inline void TTexturedLine(DEST_ &outDest,Sint16 inX1,Sint16 inX2,Sint16 inY,
                          SRC_ &inSrc, FImagePoint inS0, FImagePoint inS1)
{
   /* Fix coords */
   if ( inX1 > inX2 )
   {
      std::swap(inX1,inX2);
      std::swap(inS0,inS1);
   }   
   if (inX2<outDest.mMinX || inX1>outDest.mMaxX ||
       inY<outDest.mMinY || inY>outDest.mMaxY )
      return;

   int dx = inX2-inX1 + 1;
   FImagePoint s = inS0;
   FImagePoint ds_dx = (inS1-s)/dx;

   if (inX1<outDest.mMinX)
   {
      s+=ds_dx * (outDest.mMinX-inX1);
      inX1 = outDest.mMinX;
   }
   if (inX2>outDest.mMaxX)
      inX2 = outDest.mMaxX;

   outDest.SetPos(inX1,inY);
   for(int x=inX1;x<=inX2;x++)
   {
      inSrc.SetPos(s);
      outDest.SetAdvance<MODE_>( inSrc );
      s+= ds_dx;
   }
}

/*

 |        +  d0
dy0   xa / \         |
 |      /   \ xb    dy1
   d1  + ....\       |
        \     \
     |   \.....+ d2
     |    \   /      |
    dy2    \ /      dy3
     |      + d3     |

  Render quad in 3 phases, top middle and botton.
  Track xa and xb, the "left" and "right" (could be "right and "left")


*/

template<int MODE_,typename DEST_,typename SRC_>
void TTTSPG_QuadTex(DEST_ &outDest,ImagePoint *inDestPnt,
                    SRC_ &inSource,ImagePoint *inSrcPnt)
{
   // Convert to 16-bit fixed-point
   FImagePoint s0(inSrcPnt[0]);
   FImagePoint s1(inSrcPnt[1]);
   FImagePoint s2(inSrcPnt[2]);
   FImagePoint s3(inSrcPnt[3]);

   int dy0 = inDestPnt[1].y - inDestPnt[0].y;
   int dy1 = inDestPnt[2].y - inDestPnt[0].y;
   int dy2 = inDestPnt[3].y - inDestPnt[1].y;
   int dy3 = inDestPnt[3].y - inDestPnt[2].y;

   // The divisors here are known not to be zero ?
   Sint32 dx_dy1 = ((inDestPnt[2].x-inDestPnt[0].x)<<16)/dy1;
   Sint32 dx_dy2 = ((inDestPnt[3].x-inDestPnt[1].x)<<16)/dy2;

   FImagePoint ds_dy1 = (s2-s0)/dy1;
   FImagePoint ds_dy2 = (s3-s1)/dy2;

   Sint32 xa = inDestPnt[0].x<<16;
   Sint32 xb = xa;
   FImagePoint sa(s0);
   FImagePoint sb(s0);

   int y = inDestPnt[0].y;

   if (dy0!=0)
   {
      Sint32 dx_dy0 = ((inDestPnt[1].x-inDestPnt[0].x)<<16)/dy0;
      FImagePoint ds_dy0 = (s1-s0)/dy0;

      for(;y<inDestPnt[1].y;y++)
      {
         TTexturedLine<MODE_>(outDest,xa>>16,xb>>16, y, inSource,sa,sb);
         xa += dx_dy0;
         xb += dx_dy1;
         sa += ds_dy0;
         sb += ds_dy1;
      }
   }

   /* Middle bit of the rectangle */   
   sa = s1;
   xa = inDestPnt[1].x<<16;
   for ( ; y < inDestPnt[2].y; y++)
   {
      TTexturedLine<MODE_>(outDest,xa>>16,xb>>16, y, inSource,sa,sb);

      xa += dx_dy2;
      xb += dx_dy1;
      sa += ds_dy2;
      sb += ds_dy1;
   }
   
   /* Lower bit of the rectangle */
   sb = s2;
   xb = inDestPnt[2].x<<16;
   if( dy3==0 )
   {
      TTexturedLine<MODE_>(outDest,xa>>16,xb>>16, y, inSource,sa,sb);
   }
   else
   {
      Sint32 dx_dy3 = ((inDestPnt[3].x-inDestPnt[2].x)<<16)/dy3;
      FImagePoint ds_dy3 = (s3-s2)/dy3;

      for ( ; y <= inDestPnt[3].y ; y++)
      {
         TTexturedLine<MODE_>(outDest,xa>>16,xb>>16, y, inSource,sa,sb);

         xa += dx_dy2;
         xb += dx_dy3;
         sa += ds_dy2;
         sb += ds_dy3;
      }
   }
}


template<typename DEST_,typename SRC_>
void TTSPG_QuadTex(DEST_ &outDest,ImagePoint *inDestPnt,SRC_ &inSource,ImagePoint *inSrcPnt,Uint32 inMode)
{
   int m = inMode & 0x03;

   if (m==1)
      TTTSPG_QuadTex<1>(outDest,inDestPnt,inSource,inSrcPnt);
   else if (m==2)
      TTTSPG_QuadTex<2>(outDest,inDestPnt,inSource,inSrcPnt);
   else if (m==3)
      TTTSPG_QuadTex<3>(outDest,inDestPnt,inSource,inSrcPnt);
   else
      TTTSPG_QuadTex<0>(outDest,inDestPnt,inSource,inSrcPnt);
}

template<typename DEST_>
void TSPG_QuadTex(DEST_ &outDest,ImagePoint *inDestPnt,SDL_Surface *inSource,ImagePoint *inSrcPnt,Uint32 inMode)
{


   // TTSPG_QuadTex( outDest, inDestPnt, CounstantSource32(0xffff00,0xff), inSrcPnt, inMode);

   switch(inSource->format->BytesPerPixel)
   {
      case 1:
         TTSPG_QuadTex( outDest, inDestPnt, SurfaceSource8(inSource), inSrcPnt, inMode);
         break;
      case 3:
         TTSPG_QuadTex( outDest, inDestPnt, SurfaceSource24(inSource), inSrcPnt, inMode);
         break;
      case 4:
         TTSPG_QuadTex( outDest, inDestPnt, SurfaceSource32(inSource), inSrcPnt, inMode);
         break;
   }
}

void SPG_QuadTex1(SDL_Surface *outDest,ImagePoint *inDestPnt,SDL_Surface *inSource,ImagePoint *inSrcPnt,Uint32 inMode)
{
   /* Sort the coords */
   #define BUBBLE(a,b) \
     if (inDestPnt[a].y>inDestPnt[b].y) \
     { \
         std::swap(inDestPnt[a],inDestPnt[b]); \
         std::swap(inSrcPnt[a],inSrcPnt[b]); \
     }

   BUBBLE(0,1)
   BUBBLE(1,2)
   BUBBLE(0,1)
   BUBBLE(2,3)
   BUBBLE(1,2)
   BUBBLE(0,1)

   if( inDestPnt[0].y==inDestPnt[2].y || inDestPnt[0].y == inDestPnt[3].y ||
            inDestPnt[3].y == inDestPnt[1].y )
      return;

   
   if ( SDL_MUSTLOCK(outDest) && _SPG_lock )
      if ( SDL_LockSurface(outDest) < 0 )
         return;


   switch(outDest->format->BytesPerPixel)
   {
      case 1:
         TSPG_QuadTex( DestSurface8(outDest), inDestPnt,
                       inSource, inSrcPnt, inMode );
         break;
      case 3:
         TSPG_QuadTex( DestSurface24(outDest),inDestPnt,
                       inSource, inSrcPnt, inMode );
         break;
      case 4:
         TSPG_QuadTex( DestSurface32(outDest),inDestPnt,
                       inSource, inSrcPnt, inMode );
         break;
   }

   
   if ( SDL_MUSTLOCK(outDest) && _SPG_lock )
      SDL_UnlockSurface(outDest);

}


void SPG_QuadTex2(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Sint16 x4,Sint16 y4,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2,Sint16 sx3,Sint16 sy3,Sint16 sx4,Sint16 sy4,Uint32 inMode)
{
   ImagePoint dest_pnt[4];
   ImagePoint source_pnt[4];

   dest_pnt[0].x = x1;
   dest_pnt[0].y = y1;
   dest_pnt[1].x = x2;
   dest_pnt[1].y = y2;
   dest_pnt[2].x = x3;
   dest_pnt[2].y = y3;
   dest_pnt[3].x = x4;
   dest_pnt[3].y = y4;

   source_pnt[0].x = sx1;
   source_pnt[0].y = sy1;
   source_pnt[1].x = sx2;
   source_pnt[1].y = sy2;
   source_pnt[2].x = sx3;
   source_pnt[2].y = sy3;
   source_pnt[3].x = sx4;
   source_pnt[3].y = sy4;

   SPG_QuadTex1(dest,dest_pnt,source,source_pnt,inMode);
}


