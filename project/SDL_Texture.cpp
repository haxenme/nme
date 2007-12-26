#include "Pixel.h"
#include <algorithm>



template<int MODE_,typename DEST_,typename SRC_>
inline void TTexturedLine(DEST_ &outDest,Sint32 inX1,Sint32 inX2,Sint16 inY,
                          SRC_ &inSrc, FImagePoint inS0, FImagePoint inS1)
{
   /* Fix coords */
   if ( inX1 > inX2 )
   {
      std::swap(inX1,inX2);
      std::swap(inS0,inS1);
   }

   int px1,px2;
   if (MODE_ & SPG_HIGH_QUALITY)
   {
      px1 = (inX1 + 0x8000) >> 16;
      px2 = (inX2 + 0x8000) >> 16;
   }
   else
   {
      px1 = (inX1) >> 16;
      px2 = (inX2) >> 16;
   }

   if (px2<outDest.mMinX || px1>outDest.mMaxX ||
       inY<outDest.mMinY || inY>outDest.mMaxY || px1==px2 )
      return;

   FImagePoint s = inS0;

   // reduce to 3-bit...
   int dx = (inX2-inX1)>>13;
   FImagePoint ds_dx;
   if (dx==0)
      ds_dx = FImagePoint(0,0);
   else
      ds_dx = ((inS1-s)/dx)<<3;

   if (px1<outDest.mMinX)
   {
      if (MODE_ & SPG_HIGH_QUALITY)
      {
         s+=(ds_dx>>8) * (((outDest.mMinX<<16)+0x8000-inX1)>>8);
      }
      else
         s+=ds_dx * (outDest.mMinX-px1);

      px1 = outDest.mMinX;
   }
   else if (MODE_ & SPG_HIGH_QUALITY)
   {
      s+=(ds_dx>>8) * (((px1<<16)+0x8000-inX1)>>8);
   }

   if (px2>outDest.mMaxX)
      px2 = outDest.mMaxX;

   outDest.SetPos(px1,inY);
   for(int x=px1;x<px2;x++)
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
void TTTSPG_QuadTex(DEST_ &outDest,FImagePoint *inDestPnt,
                    SRC_ &inSource,ImagePoint *inSrcPnt)
{
   // Convert to 16-bit fixed-point
   FImagePoint s0(inSrcPnt[0]);
   FImagePoint s1(inSrcPnt[1]);
   FImagePoint s2(inSrcPnt[2]);
   FImagePoint s3(inSrcPnt[3]);

   int y0,y1,y2,y3;
   if (MODE_ & SPG_HIGH_QUALITY)
   {
      y0 = (inDestPnt[0].y + 0x8000) >> 16;
      y1 = (inDestPnt[1].y + 0x8000) >> 16;
      y2 = (inDestPnt[2].y + 0x8000) >> 16;
      y3 = (inDestPnt[3].y + 0x8000) >> 16;
   }
   else
   {
      y0 = (inDestPnt[0].y) >> 16;
      y1 = (inDestPnt[1].y) >> 16;
      y2 = (inDestPnt[2].y) >> 16;
      y3 = (inDestPnt[3].y) >> 16;
   }

   Sint32 dy0,dy1,dy2,dy3;
   Sint32 dx_dy1,dx_dy2;
   FImagePoint ds_dy1,ds_dy2;

   if (MODE_ & SPG_HIGH_QUALITY)
   {
      // Use 16 -> 3-bit precision to avoid overflow, but also reduce
      //  accumulated error when dy is large
      dy0 = (inDestPnt[1].y - inDestPnt[0].y)>>13;
      dy1 = (inDestPnt[2].y - inDestPnt[0].y)>>13;
      dy2 = (inDestPnt[3].y - inDestPnt[1].y)>>13;
      dy3 = (inDestPnt[3].y - inDestPnt[2].y)>>13;

      // This is the trangle case - we could probably handle it properly.
      if (dy1==0 || dy2==0) return;

      // Boost back to 16-bit ...
      dx_dy1 = (((inDestPnt[2].x-inDestPnt[0].x))/dy1)<<3;
      dx_dy2 = (((inDestPnt[3].x-inDestPnt[1].x))/dy2)<<3;

      ds_dy1 = ((s2-s0)/dy1)<<3;
      ds_dy2 = ((s3-s1)/dy2)<<3;
   }
   else
   {
      dy0 = y1-y0;
      dy1 = y2-y0;
      dy2 = y3-y1;
      dy3 = y3-y2;

      // This is the trangle case - we could probably handle it properly.
      if (dy1==0 || dy2==0) return;

      dx_dy1 = ((inDestPnt[2].x-inDestPnt[0].x))/dy1;
      dx_dy2 = ((inDestPnt[3].x-inDestPnt[1].x))/dy2;

      ds_dy1 = ((s2-s0)/dy1);
      ds_dy2 = ((s3-s1)/dy2);
   }



   Sint32 xa = inDestPnt[0].x;
   Sint32 xb = xa;
   FImagePoint sa(s0);
   FImagePoint sb(s0);

   int y = y0;

   if (dy0!=0)
   {
      Sint32 dx_dy0;
      FImagePoint ds_dy0 = ((s1-s0)/dy0)<<3;


      /*
         Add on fractional row to compensate for the fact that we sample the
          pixel at the centre, but the quad may have started fractionally
          above

       |       +  y0-1  |
       |                |
       |                |
       |                |
       |                |
       ----- sa^---------     ^
       |     /   \      |     |
       |   /       \    |     | = ( (y0<<16 + 0x8000) - inDestPnt[0].y 
       |                |     |
       |       +  y0    |     v

      */

      if (MODE_ & SPG_HIGH_QUALITY)
      {
         dx_dy0 = (((inDestPnt[1].x-inDestPnt[0].x))/dy0)<<3;
         ds_dy0 = ((s1-s0)/dy0)<<3;

         // reduce to 8-bit to avoid overflow...
         Sint32 yoff = ( (y<<16)+0x8000 - inDestPnt[0].y) >> 8;
         xa += (dx_dy0>>8)*yoff;
         xb += (dx_dy1>>8)*yoff;
         sa += (ds_dy0>>8)*yoff;
         sb += (ds_dy1>>8)*yoff;
      }
      else
      {
         dx_dy0 = (((inDestPnt[1].x-inDestPnt[0].x))/dy0);
         ds_dy0 = ((s1-s0)/dy0);
      }

      for(;y<y1;y++)
      {
         TTexturedLine<MODE_>(outDest,xa,xb, y, inSource,sa,sb);
         xa += dx_dy0;
         xb += dx_dy1;
         sa += ds_dy0;
         sb += ds_dy1;
      }
   }

   /* Middle bit of the quad */   
   sa = s1;
   xa = inDestPnt[1].x;
   if (MODE_ & SPG_HIGH_QUALITY)
   {
      // reduce to 8-bit to avoid overflow...
      Sint32 yoff = ((y1<<16)+0x8000 - inDestPnt[1].y) >> 8;
      xa += (dx_dy1>>8)*yoff;
      sa += (ds_dy1>>8)*yoff;
   }

   for ( ; y < y2; y++)
   {
      TTexturedLine<MODE_>(outDest,xa,xb, y, inSource,sa,sb);

      xa += dx_dy2;
      xb += dx_dy1;
      sa += ds_dy2;
      sb += ds_dy1;
   }
   

   if( dy3!=0 && y<y3 )
   {
      Sint32 dx_dy3;
      FImagePoint ds_dy3;

      /* Lower bit of the quad */
      sb = s2;
      xb = inDestPnt[2].x;
      if (MODE_ & SPG_HIGH_QUALITY)
      {
         dx_dy3 = (((inDestPnt[3].x-inDestPnt[2].x))/dy3)<<3;
         ds_dy3 = ((s3-s2)/dy3)<<3;

         // reduce to 8-bit to avoid overflow...
         Sint32 yoff = ((y2<<16)+0x8000 - inDestPnt[2].y) >> 8;
         xb += (dx_dy3>>8)*yoff;
         sb += (ds_dy3>>8)*yoff;
      }
      else
      {
         dx_dy3 = (((inDestPnt[3].x-inDestPnt[2].x))/dy3);
         ds_dy3 = ((s3-s2)/dy3);
      }

      for ( ; y < y3 ; y++)
      {
         TTexturedLine<MODE_>(outDest,xa,xb, y, inSource,sa,sb);

         xa += dx_dy2;
         xb += dx_dy3;
         sa += ds_dy2;
         sb += ds_dy3;
      }
   }
}


template<int MODE_,typename DEST_,typename SRC_>
void TTSPG_QuadTex(DEST_ &outDest,FImagePoint *inDestPnt,
                   SRC_ &inSource,ImagePoint *inSrcPnt,Uint32 inMode)
{
   if (inMode & SPG_ALPHA_BLEND)
      TTTSPG_QuadTex<MODE_ + SPG_ALPHA_BLEND>(outDest,inDestPnt,inSource,inSrcPnt);
   else
      TTTSPG_QuadTex<MODE_>(outDest,inDestPnt,inSource,inSrcPnt);
}

bool IsPOW2(int inX)
{
   return (inX & (inX-1)) == 0;
}

template<int MODE_,typename DEST_>
void TSPG_QuadTex(DEST_ &outDest,FImagePoint *inDestPnt,
                   SDL_Surface *inSource,ImagePoint *inSrcPnt,Uint32 inMode)
{

#if 0
    TTSPG_QuadTex<MODE_>( outDest, inDestPnt, CounstantSource32(0x000000,0xff), inSrcPnt, inMode);

#else

   int edge = inMode & SPG_EDGE_MASK;
   if (edge==SPG_EDGE_REPEAT && IsPOW2(inSource->w) && IsPOW2(inSource->h) )
      edge = SPG_EDGE_REPEAT_POW2;

#define SOURCE_EDGE(source) \
     if (edge == SPG_EDGE_REPEAT_POW2) \
       TTSPG_QuadTex<MODE_>( outDest, inDestPnt, \
          source<MODE_,SPG_EDGE_REPEAT_POW2>(inSource), inSrcPnt, inMode);  \
     else if (edge == SPG_EDGE_REPEAT) \
       TTSPG_QuadTex<MODE_>( outDest, inDestPnt, \
          source<MODE_,SPG_EDGE_REPEAT>(inSource), inSrcPnt, inMode);  \
     else if (edge == SPG_EDGE_UNCHECKED) \
       TTSPG_QuadTex<MODE_>( outDest, inDestPnt, \
          source<MODE_,SPG_EDGE_UNCHECKED>(inSource), inSrcPnt, inMode);  \
     else \
       TTSPG_QuadTex<MODE_>( outDest, inDestPnt, \
          source<MODE_,SPG_EDGE_CLAMP>(inSource), inSrcPnt, inMode);


   switch(inSource->format->BytesPerPixel)
   {
      case 1:
         SOURCE_EDGE(SurfaceSource8);
         break;
      case 3:
         SOURCE_EDGE(SurfaceSource24);
         break;
      case 4:
         SOURCE_EDGE(SurfaceSource32);
         break;
   }

#endif
}

template<int MODE_>
void SPG_QuadTex1(SDL_Surface *outDest,FImagePoint *inDestPnt,
                  SDL_Surface *inSource,ImagePoint *inSrcPnt,Uint32 inMode)
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
         TSPG_QuadTex<MODE_>( DestSurface8(outDest), inDestPnt,
                              inSource, inSrcPnt, inMode );
         break;
      case 3:
         TSPG_QuadTex<MODE_>( DestSurface24(outDest),inDestPnt,
                              inSource, inSrcPnt, inMode );
         break;
      case 4:
         TSPG_QuadTex<MODE_>( DestSurface32(outDest),inDestPnt,
                              inSource, inSrcPnt, inMode );
         break;
   }

   
   if ( SDL_MUSTLOCK(outDest) && _SPG_lock )
      SDL_UnlockSurface(outDest);

}

void SPG_QuadTex2(SDL_Surface *dest,Sint16 x1,Sint16 y1,
                                    Sint16 x2,Sint16 y2,
                                    Sint16 x3,Sint16 y3,
                                    Sint16 x4,Sint16 y4,
                                    SDL_Surface *source,
                                    Sint16 sx1,Sint16 sy1,
                                    Sint16 sx2,Sint16 sy2,
                                    Sint16 sx3,Sint16 sy3,
                                    Sint16 sx4,Sint16 sy4,
                                    Uint32 inMode)
{
   FImagePoint dest_pnt[4];
   ImagePoint source_pnt[4];

   dest_pnt[0].x = x1<<16;
   dest_pnt[0].y = y1<<16;
   dest_pnt[1].x = x2<<16;
   dest_pnt[1].y = y2<<16;
   dest_pnt[2].x = x3<<16;
   dest_pnt[2].y = y3<<16;
   dest_pnt[3].x = x4<<16;
   dest_pnt[3].y = y4<<16;

   source_pnt[0].x = sx1;
   source_pnt[0].y = sy1;
   source_pnt[1].x = sx2;
   source_pnt[1].y = sy2;
   source_pnt[2].x = sx3;
   source_pnt[2].y = sy3;
   source_pnt[3].x = sx4;
   source_pnt[3].y = sy4;

   SPG_QuadTex1<0>(dest,dest_pnt,source,source_pnt,inMode);
}


void SPG_QuadTexHQ(SDL_Surface *dest,Sint32 x1,Sint32 y1,
                                     Sint32 x2,Sint32 y2,
                                     Sint32 x3,Sint32 y3,
                                     Sint32 x4,Sint32 y4,
                                     SDL_Surface *source,
                                     Sint16 sx1,Sint16 sy1,
                                     Sint16 sx2,Sint16 sy2,
                                     Sint16 sx3,Sint16 sy3,
                                     Sint16 sx4,Sint16 sy4,
                                     Uint32 inMode)
{
   FImagePoint dest_pnt[4];
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

   SPG_QuadTex1<SPG_HIGH_QUALITY>(dest,dest_pnt,source,source_pnt,inMode);

}

