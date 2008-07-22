#include "texture_buffer.h"
#include <neko.h>
#include <vector>
#include "renderer/Pixel.h"

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

   static inline ARGB *Row(SDL_Surface *inSurface, int inY)
   {
      return (ARGB *)(  (char *)inSurface->pixels + inSurface->pitch*inY );
   }

   int mQuality;
};

typedef std::vector<FilterBase *> FilterSet;


class BlurFilter : public FilterBase
{
public:
   BlurFilter(value inVal) : FilterBase(inVal)
   {
   }

   SDL_Surface *Process(SDL_Surface *inSurface)
   {
      int w = inSurface->w;
      int h = inSurface->h;
      SDL_Surface *blur = CreateSurface(w,h);
      for(int y=0;y<h;y++)
      {
         ARGB *src = Row(inSurface,y);
         ARGB *dest = Row(blur,y);
         for(int x=0;x<w;x++)
         {
            dest->r = src->b;
            dest->g = src->r;
            dest->b = src->g;
            dest->a = src->a;
            src++;
            dest++;
         }
      }

      return blur;
   }

   void GetOffset(int &ioDX, int &ioDY) { }
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

         for(int q=0;q<filter.mQuality;q++)
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

