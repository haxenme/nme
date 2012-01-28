#ifndef TRIANGLE_RENDER_H
#define TRIANGLE_RENDER_H


#include <map>
#include "PolygonRender.h"


namespace nme
{
	
	class TriangleRender :public PolygonRender
	{
		struct Edge
		{
			UserPoint p0,p1;
			Edge(const UserPoint &inP0, const UserPoint &inP1) : p0(inP0), p1(inP1)
			{
				if (p1<p0) std::swap(p0,p1);
			}
			inline bool operator<(const Edge &e) const
			{
				if (p0<e.p0) return true;
				if (e.p0<p0) return false;
				return p1<e.p1;
			}
		};
		typedef std::map<Edge,int> EdgeCount;

	public:
		TriangleRender(const GraphicsJob &inJob, const GraphicsPath &inPath );

		~TriangleRender();
		void SetTransform(const Transform &inTransform);

		bool Render(const RenderTarget &inTarget, const RenderState &inState);

		int Iterate(IterateMode inMode,const Matrix &m);

		bool						mMappingDirty;
		QuickVec<AlphaMask *> mAlphaMasks;
		QuickVec<bool>		  mEdgeAA;
		GraphicsTrianglePath *mTriangles;
	};

}


#endif