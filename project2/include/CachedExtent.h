#ifndef CACHED_EXTENT_H
#define CACHED_EXTENT_H

#include <Graphics.h>

struct CachedExtent
{
	CachedExtent() : mID(0) {}
	Extent2DF Get(const Matrix &inMatrix);

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



#endif
