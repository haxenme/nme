#include <CachedExtent.h>

static int sgCachedExtentID = 1;

// --- CachedExtent --------------------------------------

Extent2DF CachedExtent::Get(const Transform &inTransform)
{
	mID = sgCachedExtentID++;
	if (!mExtent.Valid())
		return Extent2DF();
	double ratio = mTransform.mMatrix.m00!=0.0 ? inTransform.mMatrix.m00/mTransform.mMatrix.m00 :
						mTransform.mMatrix.m01!=0.0 ? inTransform.mMatrix.m01/mTransform.mMatrix.m01 : 1.0;
	Extent2DF result = mExtent;
	result.Transform(ratio, ratio, inTransform.mMatrix.mtx, inTransform.mMatrix.mty);
	return result;
}

// --- CachedExtentRenderer --------------------------------------

bool CachedExtentRenderer::GetExtent(const Transform &inTransform,Extent2DF &ioExtent)
{
	Matrix test = inTransform.mMatrix;
	double norm = test.m00*test.m00 + test.m01*test.m01 +
					  test.m10*test.m10 + test.m11*test.m11;
	if (norm<=0)
		return true;
	test = 1.0/sqrt(norm);
	test.m00 *= norm;
	test.m01 *= norm;
	test.m10 *= norm;
	test.m11 *= norm;
	test.mtx = 0;
	test.mty = 0;

	int smallest = mExtentCache[0].mID;
	int slot = 0;
	for(int i=0;i<3;i++)
	{
		CachedExtent &cache = mExtentCache[i];
		if (test==cache.mTransform.mMatrix && inTransform.mScale9==cache.mTransform.mScale9)
		{
			ioExtent.Add(cache.Get(inTransform));
			return true;
		}
		if (cache.mID<smallest)
		{
			smallest = cache.mID;
			slot = i;
		}
	}

	// Not in cache - fill slot
	CachedExtent &cache = mExtentCache[slot];
	cache.mTransform = inTransform;
	GetExtent(cache);

	cache.Get(inTransform);

	ioExtent.Add(cache.mExtent);

	return true;
}
