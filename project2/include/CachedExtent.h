#ifndef NME_CACHED_EXTENT_H
#define NME_CACHED_EXTENT_H

#include <Graphics.h>
#include <Scale9.h>

namespace nme
{


struct CachedExtent
{
	CachedExtent() : mID(0) {}
	Extent2DF Get(const Transform &inTransform);

	Transform mTransform;
	Matrix    mMatrix;
	Scale9    mScale9;
	Extent2DF mExtent;
	int       mID;
};



class CachedExtentRenderer : public Renderer
{
public:
   bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent);


	// Implement this one instead...
   virtual void GetExtent(CachedExtent &ioCache) = 0;

private:
	CachedExtent mExtentCache[3];
};

} // end namespace NME

#endif
