#ifndef POINT_RENDERER_H
#define POINT_RENDERER_H


#include "PolygonRender.h"


namespace nme
{

	class PointRenderer : public CachedExtentRenderer
	{
	public:
		
		PointRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
		void Destroy();
		virtual bool Render( const RenderTarget &inTarget, const RenderState &inState );
		virtual void GetExtent(CachedExtent &ioCache);
		virtual bool Hits(const RenderState &inState);
		void SetTransform(const Transform &inTrans);
		const QuickVec<float> &mData;
		
		int				 mData0;
		int				 mCount;
		bool				mHasColours;
		
		ARGB				mCol;
		
		Transform			  mTransform;
		QuickVec<UserPoint> mTransformed;
		
	};
	
	
}


#endif
