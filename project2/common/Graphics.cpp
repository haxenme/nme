#include <Graphics.h>


Graphics::Graphics()
{
	mLastConvertedItem = 0;
}


Graphics::~Graphics()
{
	for(int i=0;i<mCache.size();i++)
	{
		// See if we can get the extent from somewhere!
		RendererCache &cache = mCache[i];
		if (cache.mSoftware)
			cache.mSoftware->Destroy();
		if (cache.mHardware)
			cache.mHardware->Destroy();
	}

	for(int i=0;i<mItems.size();i++)
		mItems[i]->DecRef();
	mRenderData.DeleteAll();
}

void Graphics::drawGraphicsData(IGraphicsData **graphicsData,int inN)
{
	mItems.reserve(mItems.size()+inN);
	for(int i=0;i<inN;i++)
		mItems.push_back( graphicsData[i]->IncRef() );
}

void Graphics::Add(IGraphicsData *inData)
{
	mItems.push_back(inData->IncRef());
}

void Graphics::Add(IRenderData *inData)
{
	mRenderData.push_back(inData);
}


GraphicsPath *Graphics::GetLastPath()
{
	if (mLastConvertedItem<mItems.size())
	{
		IGraphicsData *last = mItems.last();
		GraphicsPath *path = last->AsPath();
		if (path)
			return path;
	}
	GraphicsPath *path = new GraphicsPath();
	Add(path);
	return path;
}



void Graphics::beginFill(unsigned int color, float alpha)
{
	Add(new GraphicsSolidFill(color,alpha));
}

void Graphics::lineTo(float x, float y)
{
	GetLastPath()->lineTo(x,y);
}

void Graphics::moveTo(float x, float y)
{
	GetLastPath()->moveTo(x,y);
}




// This routine converts a list of "GraphicsPaths" (mItems) into a list
//  of LineData and SolidData.
// The items intermix fill-styles and line-stypes with move/draw/triangle
//  geometry data - this routine separates them out.

void Graphics::CreateRenderData()
{
	int n = mItems.size();
   if (mLastConvertedItem<n)
	{
		IGraphicsFill *fill = 0;
		GraphicsStroke *stroke = 0;
		// Find "current" fill/stroke
		for(int i=0;i<mLastConvertedItem;i++)
		{
			IGraphicsData *data = mItems[i];
			IGraphicsFill *f= data->AsIFill();
			if (f)
				fill = f;
			IGraphicsStroke *s= data->AsIStroke();
			if (s)
				stroke = data->AsStroke();
		}


		SolidData *solid = 0;
		LineData *line = 0;
		for(int i=mLastConvertedItem;i<n;i++)
		{
			IGraphicsData *data = mItems[i];
			IGraphicsFill *f= data->AsIFill();
			// TODO: order of lines and solids...
			if (f)
			{
				if (solid)
				{
					solid->Close();
					Add(solid);
					solid = 0;
				}
				fill = data->AsEndFill() ? 0 : f;
				if (line)
				{
					Add(line);
					line = 0;
				}
				continue;
			}

			IGraphicsStroke *s= data->AsIStroke();
			if (s)
			{
				if (line)
				{
					Add(line);
					line = 0;
				}
				stroke = data->AsStroke();
				continue;
			}

			GraphicsPath *path= data->AsPath();
			if (path)
			{
				if (!line && stroke)
					line = new LineData(stroke);
				if (line)
					line->Add(path);
				if (!solid && fill)
					solid = new SolidData(fill);
				if (solid)
					solid->Add(path);
			}
		}
		if (solid)
			Add(solid);
		if (line)
			Add(line);

		mLastConvertedItem = n;
		mCache.resize(n);
	}

}


Extent2DF Graphics::GetExtent(const Transform &inTransform)
{
	// TODO: cache this?
	Extent2DF result;
	CreateRenderData();
	for(int i=0;i<mCache.size();i++)
	{
		// See if we can get the extent from somewhere!
		RendererCache &cache = mCache[i];
		if (cache.mSoftware && cache.mSoftware->GetExtent(inTransform,result))
			continue;
		if (cache.mHardware && cache.mHardware->GetExtent(inTransform,result))
			continue;

		// No - ok, create a software renderer...
		cache.mSoftware = mRenderData[i]->CreateSoftwareRenderer();
		cache.mSoftware->GetExtent(inTransform,result);
	}

	return result;
}



// --- Transform -------------------------------------------------------------------

bool Transform::DifferentSpace(const Transform &inRHS) const
{
	return mMatrix != inRHS.mMatrix ||
			 mScale9 != inRHS.mScale9;
}

UserPoint Transform::Apply(float inX, float inY) const
{
	if (mScale9.Active())
		return UserPoint( mScale9.TransX(inX), mScale9.TransY(inY) );
   return mMatrix.Apply(inX,inY);
}


// --- LineData -------------------------------------------------------------------

void LineData::Add(GraphicsPath *inPath)
{
	command.append(inPath->command);
	data.append(inPath->data);
}

Renderer *LineData::CreateSoftwareRenderer()
{
	return Renderer::CreateSoftware(this);
}



// --- SolidData -------------------------------------------------------------------
void SolidData::Add(GraphicsPath *inPath)
{
	command.append(inPath->command);
	data.append(inPath->data);
}

Renderer *SolidData::CreateSoftwareRenderer()
{
	return Renderer::CreateSoftware(this);
}



void SolidData::Close()
{
}



