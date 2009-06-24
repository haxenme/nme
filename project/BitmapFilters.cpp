#include "texture_buffer.h"
#include <hxCFFI.h>
#include <vector>
#include <algorithm>
#include "renderer/Pixel.h"
#include "math.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

DECLARE_KIND( k_filter_set );
DEFINE_KIND( k_filter_set );
#define FILTER_SET(v) ( (FilterSet *)(val_data(v)) )

#ifndef HXCPP
typedef value *array_ptr;
#endif


/*
#include <windows.h>
#undef min
#undef max
*/

class FilterBase
{
public:
   FilterBase(value inFilter)
   {
      value q = val_field(inFilter,val_id("quality"));
      if ( val_is_number(q))
      {
         double f = val_number(q);
         mQuality = (int)(f+0.5);
         if (mQuality<1)
            mQuality = 1;
      }
      else
         mQuality = 1;
   }

   virtual ~FilterBase() {}
   virtual SDL_Surface *Process(SDL_Surface *inSurface) = 0;
   virtual void GetOffset(int &ioDX, int &ioDY) = 0;



   virtual int GetQuality() { return mQuality; }

   int mQuality;
};

typedef std::vector<FilterBase *> FilterSet;



// -- Helpers ----------


SDL_Surface *CreateSurface(int inW,int inH)
{
   return SDL_CreateRGBSurface(SDL_SWSURFACE|SDL_SRCALPHA, inW, inH, 32,
                                  0xff0000, 0x00ff00, 0x0000ff, 0xff000000 );
}

 inline ARGB *Row(SDL_Surface *inSurface, int inY)
 {
   return (ARGB *)(  (char *)inSurface->pixels + inSurface->pitch*inY );
 }




SDL_Surface *DuplicateSurface(SDL_Surface *inSurface)
{
   SDL_Surface  *copy = CreateSurface(inSurface->w,inSurface->h);
   for(int y=0;y<inSurface->h;y++)
      memcpy(Row(copy,y),Row(inSurface,y), inSurface->w * 4);
   return copy;
}



/*
   Mask of size 4 looks like:  x+xx where + is the centre
   The blurreed image is then 2 pixel bigger in the left and one on the right
*/

void BlurRow(ARGB *inSrc, ARGB *inDest, int inDS,int inDD, int inW, int inSize)
{
   int dest_size = inW + inSize - 1;
   int sr = 0;
   int sg = 0;
   int sb = 0;
   int sa = 0;

   // loop over destination pixels with kernel    -xxx+
   // At each pixel, we - the trailing pixel and + the leading pixel
   ARGB *prev = inSrc - inDS*inSize;
   ARGB *src = inSrc;
   ARGB *dest = inDest;
   for(int x=0;x<dest_size; x++)
   {
      if (x<inW)
      {
         int a = src->a;
         sa+=a;
         sr+= src->r * a;
         sg+= src->g * a;
         sb+= src->b * a;
      }
      if (x>=inSize)
      {
         int a = prev->a;
         sa-=a;
         sr-= prev->r * a;
         sg-= prev->g * a;
         sb-= prev->b * a;
      }

      if (sa==0)
         dest->ival = 0;
      else
      {
         dest->r = sr/sa;
         dest->g = sg/sa;
         dest->b = sb/sa;
         dest->a = sa/inSize;
      }

      src+=inDS;
      prev+=inDS;

      dest+=inDD;
   }

   // Verify ...
   /*
   int a = prev->a;
   sa-=a;
   sr-= prev->r * a;
   sg-= prev->g * a;
   sb-= prev->b * a;
   if (sa || sr || sg || sb)
      *(int *)0=0;
   */
}


void BlurRow(Uint8 *inSrc, Uint8 *inDest, int inDS,int inDD, int inW, int inSize)
{
   int dest_size = inW + inSize - 1;
   int sa = 0;

   // loop over destination pixels with kernel    -xxx+
   // At each pixel, we - the trailing pixel and + the leading pixel
   Uint8 *prev = inSrc - inDS*inSize;
   Uint8 *src = inSrc;
   Uint8 *dest = inDest;
   for(int x=0;x<dest_size; x++)
   {
      if (x<inW)
         sa+=*src;
      if (x>=inSize)
         sa-=*prev;

      *dest = sa/inSize;

      src+=inDS;
      prev+=inDS;
      dest+=inDD;
   }
}

void SetRow(ARGB *inVal, int inN, ARGB inTo)
{
   int *dest = &inVal->ival;
   int src = inTo.ival;
   for(int i=0;i<inN;i++)
      dest[i] = src;
}

void ShadowRow(ARGB *inVal, int inN, ARGB inTo,bool inErase)
{
   ARGB src = inTo;
   if (inErase)
   {
      for(int i=0;i<inN;i++)
      {
         int a = inVal[i].a;
         inVal[i].ival = src.ival;
         inVal[i].a = (a*src.a)>>8;
      }
   }
   else
   {
      for(int i=0;i<inN;i++)
      {
         src.a = (inVal[i].a * inTo.a) >> 8;
         inVal[i].Blend(src);
      }
   }
}



struct AlphaImage
{
   AlphaImage(SDL_Surface *inSurface)
   {
      mWidth = inSurface->w;
      mHeight = inSurface->h;
      mData.resize(mWidth*mHeight+2);
      mData[0] = 123;
      mData[mWidth*mHeight+1] = 45;
      for(int y=0;y<mHeight;y++)
      {
         ARGB *src = ::Row(inSurface,y);
         Uint8 *dest = Row(y);
         for(int x=0;x<mWidth;x++)
            *dest++ = (src++)->a;
      }
   }
   void Verify()
   {
      if (mData[0]!=123 || mData[mWidth*mHeight+1]!=45)
      {
         printf("Verify failed.\n");
         *(int *)0=0;
      }
   }
   ~AlphaImage()
   {
      Verify();
   }

   AlphaImage(int inW,int inH)
   {
      mWidth = inW;
      mHeight = inH;
      mData.resize(mWidth*mHeight+2);
      mData[0] = 123;
      mData[mWidth*mHeight+1] = 45;
   }

   void swap(AlphaImage &inOther)
   {
      std::swap(mWidth,inOther.mWidth);
      std::swap(mHeight,inOther.mHeight);
      mData.swap(inOther.mData);
   }


   int Width() { return mWidth; }
   int Height() { return mHeight; }
   Uint8 *Row(int inY) { return & mData[ inY * mWidth + 1]; }
   int Pitch() { return mWidth; }


   int mWidth;
   int mHeight;
   std::vector<Uint8> mData;
};


// --- Blur Filter --------------------------------------------------------




class BlurFilter : public FilterBase
{
public:
   BlurFilter(value inVal) : FilterBase(inVal)
   {
      mX  = (int)val_number( val_field(inVal,val_id("blurX")) );
      //mX = (mX + mQuality/2) / mQuality;
      if (mX<1)
         mX = 1;
      mY  = (int)val_number( val_field(inVal,val_id("blurY")) );
      //mY = (mY + mQuality/2) / mQuality;
      if (mY<1) mY = 1;
   }

   SDL_Surface *Process(SDL_Surface *inSurface)
   {
      int w = inSurface->w;
      int h = inSurface->h;

      int tw = w + mX-1;
      int th = h + mY-1;

      SDL_Surface *blur_x = CreateSurface(tw,h);
      SDL_Surface *blur_y = CreateSurface(tw,th);

      // Blur rows ...
      for(int y=0;y<h;y++)
      {
         ARGB *src = Row(inSurface,y);
         ARGB *dest = Row(blur_x,y);
         BlurRow(src,dest,1,1,w,mX);
      }

      // Blur cols ...
      ARGB *src = Row(blur_x,0);
      ARGB *dest = Row(blur_y,0);
      for(int x=0;x<tw;x++)
      {
         BlurRow(src,dest, blur_x->pitch/4,blur_y->pitch/4,h,mY);
         src++;
         dest++;
      }

      SDL_FreeSurface(blur_x);

      return blur_y;
   }

   void GetOffset(int &ioDX, int &ioDY)
   {
      ioDX += mX/2;
      ioDY += mY/2;
   }

   int mX;
   int mY;
};




// --- DropShadowFilter ----------------------------------------------



class DropShadowFilter : public BlurFilter
{
public:
   DropShadowFilter(value inVal) : BlurFilter(inVal)
   {
      value theta_val = val_field(inVal,val_id("angle"));
      double theta = val_is_number(theta_val) ? val_number(theta_val) * M_PI/180.0 : 0;
      value dist_val = val_field(inVal,val_id("distance"));
      double dist = val_is_number(dist_val) ? val_number(dist_val) : 0;

      mCol  = (int)val_number( val_field(inVal,val_id("color")) );
      mStrength  = (int)(val_number( val_field(inVal,val_id("strength")) ) * 256);
      if (mStrength>0x10000)
         mStrength = 0x10000;
      mAlpha  = (int)(val_number( val_field(inVal,val_id("alpha")) )*256);
      if (mAlpha > 256) mAlpha = 256;

      mHideObject  = val_bool( val_field(inVal,val_id("hideObject")));
      mKnockout  = val_bool( val_field(inVal,val_id("knockout")) );
      mInner  = val_bool( val_field(inVal,val_id("inner")) );

      mTX = (int)( cos(theta) * dist );
      mTY = (int)( sin(theta) * dist );
   }

   // We will do the blur-iterations ourselves.
   int GetQuality() { return 1; }


   SDL_Surface *Process(SDL_Surface *inSurface)
   {

      AlphaImage alpha(inSurface);
      SDL_Surface *result = 0;

      // Blur the alpha-map
      for(int q=0;q<mQuality;q++)
      {
         // Blur rows ...
         if (mX>1)
         {
            AlphaImage blur_x(alpha.Width() + mX-1, alpha.Height());

            for(int y=0;y<alpha.mHeight;y++)
            {
               Uint8 *src = alpha.Row(y);
               Uint8 *dest = blur_x.Row(y);
               BlurRow(src,dest,1,1,alpha.mWidth,mX);
            }
            blur_x.swap(alpha);
         }

         // Blur cols ...
         if (mY>1)
         {
            AlphaImage blur_y(alpha.Width(), alpha.Height() + mY-1);

            Uint8 *src = alpha.Row(0);
            Uint8 *dest = blur_y.Row(0);
            for(int x=0;x<alpha.Width();x++)
            {
               BlurRow(src,dest, alpha.Pitch(),blur_y.Pitch(), alpha.Height(),mY);
               src++;
               dest++;
            }

            blur_y.swap(alpha);
         }
      }

      int w = inSurface->w;
      int h = inSurface->h;


      // Offset from original surface origin to top-left of blurred image
      int blur_shift_x = -(mX-1)*mQuality/2;
      int blur_shift_y = -(mY-1)*mQuality/2;
      int dx = mTX + blur_shift_x;
      int dy = mTY + blur_shift_y;

      if (mInner)
      {
         ARGB col;
         col.ival = mCol;

         result = inSurface;

         int x0 = std::max(0,dx);
         int y0 = std::max(0,dy);
         int x1 = std::min(w,alpha.Width() + dx);
         int y1 = std::min(h,alpha.Height() + dy);


         // Blank out area not overlapping
         bool erase =  (mKnockout || mHideObject);
         col.a = mAlpha;

         for(int y=0;y<y0;y++)
            ShadowRow( Row(result,y), w,col,erase);
         for(int y=y1;y<h;y++)
            ShadowRow( Row(result,y), w,col,erase);
         if (x0>0)
            for(int y=y0;y<y1;y++)
               ShadowRow( Row(result,y), x0,col,erase);
         if (x1<w)
            for(int y=y0;y<y1;y++)
               ShadowRow( Row(result,y) + x1, (w-x1),col,erase);

         int n = x1-x0;
         for(int y=y0;y<y1;y++)
         {
            Uint8 *a = alpha.Row(y-dy) + x0 - dx;
            ARGB *dest = Row(result,y) + x0 ;
            if (erase)
            {
               for(int x=0;x<n;x++)
               {
                  int val = ((255-(*a++))*mStrength) >> 8;
                  if (val>255) val = 255;
                  col.a = (dest->a*val*mAlpha) >> 16;
                  *dest = col;
                  ++dest;
               }
            }
            else
            {
               for(int x=0;x<n;x++)
               {
                  int val = ((255-(*a++))*mStrength) >> 8;
                  if (val>255) val = 255;
                  col.a = (dest->a*val*mAlpha) >> 16;
                  dest->Blend(col);
                  ++dest;
               }

            }
         }
      }
      else
      {
         int x0 = std::min(0,dx);
         int y0 = std::min(0,dy);
         int x1 = std::max(w,alpha.Width() + dx);
         int y1 = std::max(h,alpha.Height() + dy);


         result = CreateSurface(x1-x0,y1-y0);
         int col = mCol;

         // Starting position of alpha, in destination coordinates...
         int alpha_x = dx - x0;
         int alpha_y = dy - y0;

         for(int y=0;y<alpha.Height();y++)
         {
            Uint8 *a = alpha.Row(y);
            ARGB *dest = Row(result,y + alpha_y) + alpha_x;

            for(int x=0;x<alpha.Width();x++)
            {
               int val = ((*a++)*mStrength) >> 8;
               if (val>255) val = 255;
               val = (val*mAlpha) >> 8;
               dest->ival = col | ((val)<<24);
               ++dest;
            }
         }

         // Now Blend original over the top, if required

         if (mKnockout)
         {
            for(int y=0;y<inSurface->h;y++)
            {
               ARGB *src = Row(inSurface,y);
               ARGB *dest = Row(result,y-y0) - x0;
               for(int x=0;x<w;x++)
               {
                  dest->a = (dest->a * (255-src->a)) >> 8;
                  src++;
                  dest++;
               }
            }
         }
         else if (!mHideObject)
         {
            for(int y=0;y<inSurface->h;y++)
            {
               ARGB *src = Row(inSurface,y);
               ARGB *dest = Row(result,y-y0) - x0;
               for(int x=0;x<w;x++)
               {
                  dest->Blend(*src);
                  src++;
                  dest++;
               }
            }
         }
      }

      return result;
   }

   void GetOffset(int &ioDX, int &ioDY)
   {
      if (!mInner)
      {
         int dx = mTX-(mX-1)*mQuality/2;
         int dy = mTY-(mY-1)*mQuality/2;
         int x0 = std::min(0,dx);
         int y0 = std::min(0,dy);

         ioDX += x0;
         ioDY += y0;
      }
   }

   int mTX;
   int mTY;
   int mCol;
   int mStrength;
   int mAlpha;
   bool mHideObject;
   bool mKnockout;
   bool mInner;
};




// --------------------------------------------------------

value nme_filter_image(value inFilterSet,value inTextureBuffer)
{
   if ( !val_is_kind( inFilterSet, k_filter_set ) )
      return val_null;

   if ( !val_is_kind( inTextureBuffer, k_texture_buffer ) )
      return val_null;

   FilterSet &filters = *FILTER_SET(inFilterSet);
   TextureBuffer *tex = TEXTURE_BUFFER(inTextureBuffer);

   SDL_Surface *surface = tex->GetSourceSurface();

   // Create copy, and ensure correct format...
   //surface = SDL_ConvertSurface(surface, surface->format, surface->flags);
   surface = DuplicateSurface(surface);

   for(size_t i=0;i<filters.size();i++)
   {
      FilterBase &filter = *filters[i];
      int quality = filter.GetQuality();

      for(int q=0;q<quality;q++)
      {
         SDL_Surface *processed = filter.Process(surface);
         if (processed != surface)
            SDL_FreeSurface(surface);

         surface = processed;
      }
   }


   TextureBuffer *result = new TextureBuffer(surface);
   return result->ToValue();
}

void delete_filter_set(value inFilters)
{
   if ( val_is_kind( inFilters, k_filter_set ) )
   {
      val_gc( inFilters, NULL );

      FilterSet *filters = FILTER_SET(inFilters);
      for(size_t i=0;i<filters->size();i++)
         delete (*filters)[i];
      delete filters;
   }
}

value nme_create_filter_set(value inFilters,value outPoint)
{
   FilterSet *result = new FilterSet;

   val_check( inFilters, array );
   int n =  val_array_size(inFilters);

   int ox = 0;
   int oy = 0;
   for(int i=0;i<n;i++)
   {
      value val = val_array_i(inFilters,i);
      #ifdef HXCPP
      value type_val = val_field(val,val_id("mType"));
      #else
      value type_val_obj = val_field(val,val_id("mType"));
      if ( !val_is_object(type_val_obj) )
         hx_failure( "no filter type found" );

      value type_val = val_field(type_val_obj,val_id("__s"));
      if ( !val_is_string(type_val) )
         hx_failure( "no filter type string found" );
      #endif


      const char *type =  val_string(type_val);
      FilterBase *filter = 0;
      if (!strcmp(type,"BlurFilter"))
      {
         filter = new BlurFilter(val);
      }
      else if (!strcmp(type,"DropShadowFilter"))
      {
         filter = new DropShadowFilter(val);
      }

      if (filter)
      {
         filter->GetOffset(ox,oy);
         result->push_back(filter);
      }
   }

   alloc_field( outPoint, val_id( "x" ), alloc_float( ox ) );
   alloc_field( outPoint, val_id( "y" ), alloc_float( oy ) );

   value v = alloc_abstract( k_filter_set, result );
   val_gc( v, delete_filter_set );
   return v;
}



DEFINE_PRIM(nme_filter_image, 2);
DEFINE_PRIM(nme_create_filter_set, 2);

int __force_BitmapFilters = 0;
