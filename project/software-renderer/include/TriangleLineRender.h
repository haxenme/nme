#ifndef TRIANGLE_LINE_RENDER_H
#define TRIANGLE_LINE_RENDER_H


#include "LineRender.h"


namespace nme
{
	
	class TriangleLineRender : public LineRender
	{
	public:
		
		TriangleLineRender(const GraphicsJob &inJob, const GraphicsPath &inPath, Renderer *inSolid);
		~TriangleLineRender();

		bool Render( const RenderTarget &inTarget, const RenderState &inState );

		bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent);

		bool Hits(const RenderState &inState);
		int Iterate(IterateMode inMode,const Matrix &m);
		void SetTransform(const Transform &inTransform);
		
		Renderer *mSolid;
		GraphicsTrianglePath *mTriangles;
	};
	
}


#endif