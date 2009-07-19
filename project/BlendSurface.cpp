#include "DrawObject.h"

#define BLEND_ARGS inSrc,outDest,sx0,sy0,w,h,dx0,dy0

inline int Clamp255(int inX) { return inX>255 ? 255 : inX; }

struct BlendAdd
{
   template<typename SRC,typename DEST>
   inline static void Blend(const SRC &inSrc, DEST &ioDest)
   {
      if (!SRC::HasAlpha || inSrc.a>250)
      {
         ioDest.c0 = Clamp255( inSrc.c0 + ioDest.c0 );
         ioDest.c1 = Clamp255( inSrc.c1 + ioDest.c1 );
         ioDest.c2 = Clamp255( inSrc.c2 + ioDest.c2 );
         //if (DEST::HasAlpha)
            //ioDest.a = 255;
      }
      else
      {
         int a = inSrc.a;
         ioDest.c0 = Clamp255( inSrc.c0 + ((ioDest.c0*a)>>8) );
         ioDest.c1 = Clamp255( inSrc.c1 + ((ioDest.c1*a)>>8) );
         ioDest.c2 = Clamp255( inSrc.c2 + ((ioDest.c2*a)>>8) );
         //if (DEST::HasAlpha)
            //ioDest.a = Clamp255( ioDest.a + a );
      }
   }
};

struct BlendMultiply
{
   #define MBLEND(x) (256 - (((256-x)*a)>>8) )

   template<typename SRC,typename DEST>
   inline static void Blend(const SRC &inSrc, DEST &ioDest)
   {
      if (!SRC::HasAlpha || inSrc.a>250)
      {
         ioDest.c0 = ( inSrc.c0 * (ioDest.c0+1) )>>8;
         ioDest.c1 = ( inSrc.c1 * (ioDest.c1+1) )>>8;
         ioDest.c2 = ( inSrc.c2 * (ioDest.c2+1) )>>8;
      }
      else
      {
         int a = inSrc.a;
         ioDest.c0 = ( inSrc.c0 * MBLEND(ioDest.c0) ) >> 8;
         ioDest.c1 = ( inSrc.c1 * MBLEND(ioDest.c1) ) >> 8;
         ioDest.c2 = ( inSrc.c2 * MBLEND(ioDest.c2) ) >> 8;
      }
   }
};



template<typename SRC,typename DEST,typename BLENDER>
void TBlendSurfaceFunc( SDL_Surface *inSrc, SDL_Surface *outDest,
                   int sx0, int sy0, int w, int h, int dx0, int dy0)
{
   for(int y=0;y<h;y++)
   {
      SRC *src = (SRC *)((char *)inSrc->pixels + inSrc->pitch*(y+sy0)) + sx0;
      DEST *dest = (DEST *)((char *)outDest->pixels + outDest->pitch*(y+dy0)) + dx0;
      for(int x=0;x<w;x++)
      {
         if (!SRC::HasAlpha || src[x].a>5)
            BLENDER::Blend(src[x],dest[x]);
      }
   }
}



template<typename SRC,typename DEST>
void TBlendSurface(int inMode, SDL_Surface *inSrc, SDL_Surface *outDest,
                   int sx0, int sy0, int w, int h, int dx0, int dy0)
{
   switch(inMode)
   {
      case BLEND_ADD:
         TBlendSurfaceFunc<SRC,DEST,BlendAdd>(BLEND_ARGS);
         break;
      case BLEND_MULTIPLY:
         TBlendSurfaceFunc<SRC,DEST,BlendMultiply>(BLEND_ARGS);
         break;
   }
}



void BlendSurface(SDL_Surface *inSrc, SDL_Rect *inSrcRect,
                  SDL_Surface *outDest, SDL_Rect *inDestOffset,
                  int inMode)
{
   if (outDest->format->BytesPerPixel!=4 || outDest->format->BytesPerPixel!=4 )
      return;

   int sx0 = 0;
   int sy0 = 0;
   int w = inSrc->w;
   int h = inSrc->h;
   if (inSrcRect)
   {
      sx0 = inSrcRect->x;
      sy0 = inSrcRect->y;
      w = inSrcRect->w;
      h = inSrcRect->h;
   }
   int dx0 = inDestOffset ? inDestOffset->x : 0;
   int dy0 = inDestOffset ? inDestOffset->y : 0;
   if (dx0<0)
   {
      sx0 -= dx0;
      w += dx0;
      dx0 = 0;
   }
   if (dy0<0)
   {
      sy0 -= dy0;
      h += dy0;
      dy0 = 0;
   }

   if (dx0+w>outDest->w)
   {
      w = outDest->w - dx0;
      if (w<=0) return;
   }
   if (dy0+h>outDest->h)
   {
      h = outDest->h - dy0;
      if (h<=0) return;
   }


   if (sx0>=0 && sy0>=0 && sx0+w<=inSrc->w && sy0+h<=inSrc->h)
   {

      if ( SDL_MUSTLOCK(outDest) )
         if ( SDL_LockSurface(outDest) < 0 )
            return;

      if (outDest->format->Amask)
      {
          if (inSrc->format->Amask)
             TBlendSurface<ARGB,ARGB>(inMode,BLEND_ARGS);
          else
             TBlendSurface<XRGB,ARGB>(inMode,BLEND_ARGS);
      }
      else
      {
          if (inSrc->format->Amask)
             TBlendSurface<ARGB,XRGB>(inMode,BLEND_ARGS);
          else
             TBlendSurface<XRGB,XRGB>(inMode,BLEND_ARGS);
      }


      if ( SDL_MUSTLOCK(outDest)  )
         SDL_UnlockSurface(outDest);
   }
}




