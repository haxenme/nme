#include "texture_buffer.h"
#include <neko.h>
#include <vector>

DECLARE_KIND( k_filter_set );
DEFINE_KIND( k_filter_set );
#define FILTER_SET(v) ( (FilterSet *)(val_data(v)) )


class FilterBase
{
public:
   virtual ~FilterBase() {}
   virtual SDL_Surface *Process(SDL_Surface *inSurface) = 0;
   virtual void GetOffset(int &ioDX, int &ioDY) = 0;
};

typedef std::vector<FilterBase *> FilterSet;




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
      for(size_t i=0;i<filters.size();i++)
      {
         FilterBase &filter = *filters[i];
         SDL_Surface *processed = filter.Process(surface);
         if (i>0)
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

   value v = alloc_abstract( k_filter_set, result );
   val_gc( v, delete_filter_set );
   return v;
}



DEFINE_PRIM(nme_filter_image, 2);
DEFINE_PRIM(nme_create_filter_set, 2);

