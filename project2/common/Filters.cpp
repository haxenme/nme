#include <Graphics.h>
#include <Display.h>
#include <Surface.h>

namespace nme
{

// Calculate the filtered rect size, given input rect
Rect GetFilteredRect(const Filters &inFilters,const Rect &inObjRect)
{
   return inObjRect;
}

// Find minimal pixels we should render to create correct target rectangle
Rect GetRectToCreateFiltered(const Filters &inFilters,const Rect &inTargetRect)
{
   return inTargetRect;
}

// Perform filter into given target rect
void FilterBitmap(const Filters &inFilters,SimpleSurface *&bitmap, const Rect &inSrcRect, const Rect &inVisible, bool inMakePOW2)
{
}


 
} // end namespace nme


