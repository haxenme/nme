#include <Graphics.h>
#include "TriangleRender.h"
#include "TriangleLineRender.h"
#include "TileRenderer.h"
#include "PointRenderer.h"
#include "LineRender.h"
#include "SolidRender.h"


namespace nme
{
	
  	Lines sLineBuffer;
	AlphaRuns *sLines = 0;
	Transitions *sTransitions = 0;
	std::vector<Transitions> sTransitionsBuffer;

	Renderer *Renderer::CreateSoftware(const GraphicsJob &inJob, const GraphicsPath &inPath)
	{
		if (inJob.mTriangles)
		{
			Renderer *solid = 0;
			if (inJob.mFill)
			 solid = new TriangleRender(inJob,inPath);
			return inJob.mStroke ? new TriangleLineRender(inJob,inPath,solid) : solid;
		}
		else if (inJob.mIsTileJob)
		  return new TileRenderer(inJob,inPath);
		else if (inJob.mIsPointJob)
		  return new PointRenderer(inJob,inPath);
		else if (inJob.mStroke)
		  return new LineRender(inJob,inPath);
		else
		  return new SolidRender(inJob,inPath);
	}


}
