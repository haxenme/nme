#include "TriangleRender.h"


namespace nme
{
	
	TriangleRender::TriangleRender(const GraphicsJob &inJob, const GraphicsPath &inPath): PolygonRender(inJob, inPath, inJob.mFill)
	{
		mTriangles = inJob.mTriangles;
		mAlphaMasks.resize(mTriangles->mTriangleCount);
		mAlphaMasks.Zero();

		mMappingDirty = true;
		int n  = mTriangles->mTriangleCount;
		const UserPoint *p = &mTriangles->mVertices[0];
	
		EdgeCount edges;
		for(int t=0;t<n;t++)
		{
			 edges[ Edge(p[0],p[1]) ]++;
			 edges[ Edge(p[1],p[2]) ]++;
			 edges[ Edge(p[2],p[0]) ]++;
			 p+=3;
		}

		p = &mTriangles->mVertices[0];
		int idx=0;
		mEdgeAA.resize(n*3);
		for(int t=0;t<n;t++)
		{
			 mEdgeAA[idx++] = edges[Edge(p[0],p[1])]<2;
			 mEdgeAA[idx++] = edges[Edge(p[1],p[2])]<2;
			 mEdgeAA[idx++] = edges[Edge(p[2],p[0])]<2;
			 p+=3;
		}
	}
	
	
	TriangleRender::~TriangleRender()
	{
		for(int i=0;i<mAlphaMasks.size();i++)
			if (mAlphaMasks[i])
			  mAlphaMasks[i]->Dispose();
	}
	
	
	int TriangleRender::Iterate(IterateMode inMode,const Matrix &m)
	{
		const UserPoint *point = 0;

		if (inMode==itHitTest)
			point = (const UserPoint *)&mTriangles->mVertices[0];
		else
			point = &mTransformed[0];


		int points = mTriangles->mVertices.size();
		if (inMode==itGetExtent)
		{
			for(int p=0;p<points;p++)
				mBuildExtent->Add(point[p]);
		}
		else
		{
			typedef void (PolygonRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
			ItFunc func = inMode==itCreateRenderer ? &PolygonRender::BuildSolid :
						&PolygonRender::BuildHitTest;

			int tris = mTriangles->mTriangleCount;
			for(int t=0;t<tris;t++)
			{
				(*this.*func)(point[0],point[1]);
				(*this.*func)(point[1],point[2]);
				(*this.*func)(point[2],point[0]);
				point += 3;
			}
		}
		return 256;
	}
	
	
	bool TriangleRender::Render(const RenderTarget &inTarget, const RenderState &inState)
	{
		if (mTriangles->mUVT.empty())
			return PolygonRender::Render(inTarget,inState);

		Extent2DF extent;
		CachedExtentRenderer::GetExtent(inState.mTransform,extent);

		if (!extent.Valid())
			return true;

		// Get bounding pixel rect
		Rect rect = inState.mTransform.GetTargetRect(extent);

		// Intersect with clip rect ...
		Rect visible_pixels = rect.Intersect(inState.mClipRect);
	  

		int tris = mTriangles->mTriangleCount;
		UserPoint *point = &mTransformed[0];
		bool *edge_aa = &mEdgeAA[0];
		float *uvt = &mTriangles->mUVT[0];
		int tex_components = mTriangles->mType == vtVertex ? 0 : mTriangles->mType==vtVertexUV ? 2 : 3;
		int  aa = inState.mTransform.mAAFactor;
		bool aa1 = aa==1;
		for(int i=0;i<tris;i++)
		{
			// For each alpha mask ...
			// Check to see if AlphaMask is invalid...
			AlphaMask *&alpha = mAlphaMasks[i];
			int tx=0;
			int ty=0;
			if (alpha && !alpha->Compatible(inState.mTransform, rect,visible_pixels,tx,ty))
			{
				alpha->Dispose();
				alpha = 0;
			}

			if (!alpha)
			{
				SetTransform(inState.mTransform);
	
				SpanRect *span = new SpanRect(visible_pixels,inState.mTransform.mAAFactor);

				if (aa1 || edge_aa[0])
					span->Line<false,true>( mTransform.ToImageAA(point[0]),mTransform.ToImageAA(point[1]) );
				else
					span->Line<true,true>( mTransform.ToImageAA(point[0]),mTransform.ToImageAA(point[1]) );

				if (aa1 || edge_aa[1])
					span->Line<false,true>( mTransform.ToImageAA(point[1]),mTransform.ToImageAA(point[2]) );
				else
					span->Line<true,true>( mTransform.ToImageAA(point[1]),mTransform.ToImageAA(point[2]) );

				if (aa1 || edge_aa[2])
					span->Line<false,true>( mTransform.ToImageAA(point[2]),mTransform.ToImageAA(point[0]) );
				else
					span->Line<true,true>( mTransform.ToImageAA(point[2]),mTransform.ToImageAA(point[0]) );

				alpha = span->CreateMask(mTransform,256);
				delete span;
			}


	
			if (inTarget.mPixelFormat==pfAlpha)
			{
				alpha->RenderBitmap(tx,ty,inTarget,inState);
			}
			else
			{
				if (tex_components)
					mFiller->SetMapping(point,uvt,tex_components);

				mFiller->Fill(*alpha,tx,ty,inTarget,inState);
			}

			point += 3;
			uvt+=tex_components*3;
			edge_aa += 3;
		}

		mMappingDirty = false;

		return true;
	}
	
	
	void TriangleRender::SetTransform(const Transform &inTransform)
	{
		int points = mTriangles->mVertices.size();
		if (points!=mTransformed.size() || inTransform!=mTransform)
		{
			mMappingDirty = true;
			mTransform = inTransform;
			mTransMat = *inTransform.mMatrix;
			mTransform.mMatrix = &mTransMat;
			mTransform.mMatrix3D = &mTransMat;
			mTransScale9 = *inTransform.mScale9;
			mTransform.mScale9 = &mTransScale9;
			mTransformed.resize(points);
			UserPoint *src= (UserPoint *)&mTriangles->mVertices[ 0 ];
			for(int i=0;i<points;i++)
				mTransformed[i] = mTransform.Apply(src[i].x,src[i].y);
		}
	}
	
}
