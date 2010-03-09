#include <Graphics.h>
#include <Display.h>
#include <Surface.h>

namespace nme
{

Rect ExpandVisibleFilterDomain( const FilterList &inList, const Rect &inRect )
{
   return inRect;
}

Rect GetFilteredObjectRect(const Rect &inRect)
{
   return inRect;
}



Surface *FilterBitmap(Surface *inBitmap, const FilterList &inFilters,
                       const Rect &inSrcRect, const Rect &outDestRect, bool inMakePOW2)
{
   return inBitmap;
}

 
} // end namespace nme


