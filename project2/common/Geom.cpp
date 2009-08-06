#include <Graphics.h>
#include <algorithm>

Rect Rect::Intersect(const Rect &inOther) const
{
   int x0 = std::max(x,inOther.x);
   int y0 = std::max(y,inOther.y);
   int x1 = std::min(x,inOther.x);
   int y1 = std::min(y,inOther.y);

	return Rect(x0,y0,x1>x0 ? x1-x0 : 0, y1>y0 ? y1-y0 : 0);
}
