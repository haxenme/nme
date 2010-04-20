#include <Graphics.h>

namespace nme
{

// --- GraphicsPath ------------------------------------------

void GraphicsPath::initPosition(const UserPoint &inPoint)
{
   commands.push_back(pcBeginAt);
   data.push_back(inPoint.x);
   data.push_back(inPoint.y);
}

void GraphicsPath::clear()
{
   commands.resize(0);
   data.resize(0);
}



void GraphicsPath::curveTo(float controlX, float controlY, float anchorX, float anchorY)
{
	commands.push_back(pcCurveTo);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}

void GraphicsPath::arcTo(float controlX, float controlY, float anchorX, float anchorY)
{
	commands.push_back(pcArcTo);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}


void GraphicsPath::lineTo(float x, float y)
{
	commands.push_back(pcLineTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::moveTo(float x, float y)
{
	commands.push_back(pcMoveTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::wideLineTo(float x, float y)
{
	commands.push_back(pcLineTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::wideMoveTo(float x, float y)
{
	commands.push_back(pcMoveTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::tile(float x, float y, const Rect &inTileRect)
{
	commands.push_back(pcTile);
	data.push_back(x);
	data.push_back(y);
	data.push_back(inTileRect.x);
	data.push_back(inTileRect.y);
	data.push_back(inTileRect.w);
	data.push_back(inTileRect.h);
}

void GraphicsPath::drawPoints(QuickVec<float> inXYs, QuickVec<int> inRGBAs)
{
   int n = inXYs.size()/2;
   int d0 = data.size();

   if (inRGBAs.size()==n)
   {
       commands.push_back(pcPointsXYRGBA);
       data.resize(d0 + n*3);
       memcpy(&data[d0], &inXYs[0], n*2*sizeof(float));
       d0+=n*2;
       memcpy(&data[d0], &inRGBAs[0], n*sizeof(int));
   }
   else
   {
       commands.push_back(pcPointsXY);
       data.resize(d0 + n*2);
       memcpy(&data[d0], &inXYs[0], n*sizeof(float));
   }
}

// -- GraphicsTrianglePath ---------------------------------------------------------

GraphicsTrianglePath::GraphicsTrianglePath( const QuickVec<float> &inXYs,
            const QuickVec<int> &inIndices,
            const QuickVec<float> &inUVT, int inCull)
{
	UserPoint *v = (UserPoint *) &inXYs[0];
	int v_count = inXYs.size()/2;
	int uv_parts = inUVT.size()==v_count*2 ? 2 : inUVT.size()==v_count*3 ? 3 : 0;
	const float *uvt = &inUVT[0];

	if (inIndices.empty())
	{
		int t_count = v_count/3;
		if (inCull==tcNone)
		{
			mVertices.resize(6*t_count);
			memcpy(&mVertices[0],v,3*sizeof(UserPoint));
			if (uv_parts)
			{
				mUVT.resize(uv_parts*3*t_count);
				memcpy(&mUVT[0],&inUVT[0],uv_parts*sizeof(UserPoint));
			}
		}
		else
		{
			for(int i=0;i<t_count;i++)
			{
				UserPoint p0 = *v++;
				UserPoint p1 = *v++;
				UserPoint p2 = *v++;
				if ( (p1-p0).Cross(p2-p0)*inCull > 0)
				{
					mTriangleCount++;
					mVertices.push_back(p0);
					mVertices.push_back(p1);
					mVertices.push_back(p2);
					for(int i=0;i<uv_parts*3;i++)
						mUVT.push_back( *uvt++ );
				}
				else
					uvt += uv_parts;
			}
		}
	}
	else
	{
		const int *idx = &inIndices[0];
		int t_count = inIndices.size()/3;
		for(int i=0;i<t_count;i++)
		{
			int i0 = *idx++;
			int i1 = *idx++;
			int i2 = *idx++;
			if (i0>=0 && i1>=0 && i2>=0 && i0<v_count && i1<v_count && i2<v_count)
			{
				UserPoint p0 = v[i0];
				UserPoint p1 = v[i1];
				UserPoint p2 = v[i2];
				if ( (p1-p0).Cross(p2-p0)*inCull >= 0)
				{
					mVertices.push_back(p0);
					mVertices.push_back(p1);
					mVertices.push_back(p2);
					if (uv_parts)
					{
						const float *f = uvt + uv_parts*i0;
						for(int i=0;i<uv_parts;i++) mUVT.push_back( *f++ );
						f = uvt + uv_parts*i1;
						for(int i=0;i<uv_parts;i++) mUVT.push_back( *f++ );
						f = uvt + uv_parts*i2;
						for(int i=0;i<uv_parts;i++) mUVT.push_back( *f++ );
					}
				}
			}
		}
	}

	mTriangleCount = mVertices.size()/3;
   mType = uv_parts==2 ? vtVertexUV : uv_parts==3? vtVertexUVT : vtVertex;
}



} // end namespace nme

