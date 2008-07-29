#include "texture_buffer.h"
#include <neko.h>
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
      }
      else
         mQuality = 1;
   }

   virtual ~FilterBase() {}
   virtual SDL_Surface *Process(SDL_Surface *inSurface) = 0;
   virtual void GetOffset(int &ioDX, int &ioDY) = 0;

   SDL_Surface *CreateSurface(int inW,int inH)
   {
      return SDL_CreateRGBSurface(SDL_SWSURFACE|SDL_SRCALPHA, inW, inH, 32,
                                  0xff0000, 0x00ff00, 0x0000ff, 0xff000000 );
   }


   virtual int GetQuality() { return mQuality; }

   int mQuality;
};

typedef std::vector<FilterBase *> FilterSet;



// -- Helpers ----------


 inline ARGB *Row(SDL_Surface *inSurface, int inY)
 {
   return (ARGB *)(  (char *)inSurface->pixels + inSurface->pitch*inY );
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



struct AlphaImage
{
   AlphaImage(SDL_Surface *inSurface)
   {
      mWidth = inSurface->w;
      mHeight = inSurface->h;
      mData.resize(mWidth*mHeight);
      for(int y=0;y<mHeight;y++)
      {
         ARGB *src = ::Row(inSurface,y);
         Uint8 *dest = Row(y);
         for(int x=0;x<mWidth;x++)
            *dest++ = (src++)->a;
      }
   }

   AlphaImage(int inW,int inH)
   {
      mWidth = inW;
      mHeight = inH;
      mData.resize(mWidth*mHeight);
   }

   void swap(AlphaImage &inOther)
   {
      std::swap(mWidth,inOther.mWidth);
      std::swap(mHeight,inOther.mHeight);
      mData.swap(inOther.mData);
   }


   int Width() { return mWidth; }
   int Height() { return mHeight; }
   Uint8 *Row(int inY) { return & mData[ inY * mWidth ]; }
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
      if (mX<1) mX = 1;
      mY  = (int)val_number( val_field(inVal,val_id("blurY")) );
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
      double theta  = val_number( val_field(inVal,val_id("angle")) ) * M_PI/180.0;
      double dist = val_number( val_field(inVal,val_id("distance")) );
      mCol  = (int)val_number( val_field(inVal,val_id("color")) );
      mStrength  = (int)val_number( val_field(inVal,val_id("strength")) );
      if (mStrength>255) mStrength = 255;
      mAlpha  = (int)(val_number( val_field(inVal,val_id("alpha")) )*256);
      if (mAlpha > 256) mAlpha = 256;
      mHideObject  = val_bool( val_field(inVal,val_id("hideObject")));

      mTX = (int)( cos(theta) * dist );
      mTY = (int)( sin(theta) * dist );
   }

   // We will do the blur-iterations ourselves.
   int GetQuality() { return 1; }


   SDL_Surface *Process(SDL_Surface *inSurface)
   {
      AlphaImage alpha(inSurface);

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
               BlurRow(src,dest,1,1,alpha.Width(),mX);
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

      // Offset from original surface origin to 
      int dx = mTX-(mX-1)*mQuality;
      int dy = mTY-(mY-1)*mQuality;

      int x0 = std::min(0,dx);
      int y0 = std::min(0,dy);
      int x1 = std::max(inSurface->w,alpha.Width() + dx);
      int y1 = std::max(inSurface->h,alpha.Height() + dy);

      int w = x1-x0;
      int h = y1-y0;

      SDL_Surface *result = CreateSurface(w,h);

      // Apply alpha shadow ...
      int col = mCol;
      for(int y=0;y<alpha.Height();y++)
      {
         Uint8 *a = alpha.Row(y);
         ARGB *dest = Row(result, y + (dy-y0)) + (dx-x0);
         for(int x=0;x<alpha.Width();x++)
         {
            int val = (*a++)*mStrength;
            if (val>255) val = 255;
            val = (val*mAlpha) >> 8;
            (++dest)->ival = col | ((val)<<24);
         }
      }

      // Now Blend original over the top ...
      if (!mHideObject)
      {
         int w = inSurface->w;
         int h = inSurface->h;
         for(int y=0;y<inSurface->h;y++)
         {
            ARGB *src = Row(inSurface,y);
            ARGB *dest = Row(result,y);
            for(int x=0;x<w;x++)
            {
               int sa = src->a;
               int da = dest->a;

               if (sa>5)
               {
                  if (sa>250 || da<5)
                     dest->ival = src->ival;
                  else
                  {
                     int alpha16 = ((da + sa)<<8) - da*sa;
                     int c1 = (255-sa) * da;
                     sa<<=8;
                     dest->r = (sa*src->r + c1*dest->r)/alpha16;
                     dest->g = (sa*src->g + c1*dest->g)/alpha16;
                     dest->b = (sa*src->b + c1*dest->b)/alpha16;
                     dest->a = alpha16>>8;
                  }
               }

               src++;
               dest++;
            }
         }
      }

      return result;
   }

   void GetOffset(int &ioDX, int &ioDY)
   {
      ioDX += (mX/2)*mQuality - mTX;
      ioDY += (mY/2)*mQuality - mTY;
   }

   int mTX;
   int mTY;
   int mCol;
   int mStrength;
   int mAlpha;
   bool mHideObject;
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

   if (filters.size()==0)
   {
      surface = SDL_ConvertSurface(surface, surface->format, surface->flags);
   }
   else
   {
      bool first = true;
      for(size_t i=0;i<filters.size();i++)
      {
         FilterBase &filter = *filters[i];
         int quality = filter.GetQuality();

         for(int q=0;q<quality;q++)
         {
            SDL_Surface *processed = filter.Process(surface);
            if (!first)
               SDL_FreeSurface(surface);
            first = false;
            surface = processed;
         }
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
   value *objs =  val_array_ptr(inFilters);
   int n =  val_array_size(inFilters);

   int ox = 0;
   int oy = 0;
   for(int i=0;i<n;i++)
   {
      value val = objs[i];
      value type_val_obj = val_field(val,val_id("mType"));
      if ( !val_is_object(type_val_obj) )
         failure( "no filter type found" );

      value type_val = val_field(type_val_obj,val_id("__s"));
      if ( !val_is_string(type_val) )
         failure( "no filter type string found" );


      char *type =  val_string(type_val);
      FilterBase *filter = 0;
      // printf("Creating filter %s\n",type);
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


   value v = alloc_abstract( k_filter_set, result );
   val_gc( v, delete_filter_set );
   return v;
}



DEFINE_PRIM(nme_filter_image, 2);
DEFINE_PRIM(nme_create_filter_set, 2);

