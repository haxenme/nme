#include <Graphics.h>
#include <algorithm>

// --- Rect -------------------------------------------------------------------

Rect Rect::Intersect(const Rect &inOther) const
{
   int x0 = std::max(x,inOther.x);
   int y0 = std::max(y,inOther.y);
   int x1 = std::min(this->x1(),inOther.x1());
   int y1 = std::min(this->y1(),inOther.y1());

	return Rect(x0,y0,x1>x0 ? x1-x0 : 0, y1>y0 ? y1-y0 : 0);
}

// --- Transform -------------------------------------------------------------------

Transform::Transform()
{
	mStageScaleX = 1.0;
	mStageScaleY = 1.0;
	mStageOX = 0.0;
	mStageOY = 0.0;
}

UserPoint Transform::Apply(float inX, float inY) const
{
	if (mScale9.Active())
	{
		inX = mScale9.TransX(inX);
		inY = mScale9.TransY(inY);
	}
	return UserPoint( (mMatrix.m00*inX + mMatrix.m01*inY + mMatrix.mtx) ,
	                  (mMatrix.m10*inX + mMatrix.m11*inY + mMatrix.mty) );
}



bool Transform::operator==(const Transform &inRHS) const
{
	return mMatrix==inRHS.mMatrix && mScale9==inRHS.mScale9 &&
          mStageScaleX==inRHS.mStageScaleX && mStageScaleY==inRHS.mStageScaleY;
}
