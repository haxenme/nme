#ifndef TILE_RENDERER_H
#define TILE_RENDERER_H


#include "PolygonRender.h"


namespace nme
{
	
	const double one_on_255 = 1.0/255.0;
	
	class TileRenderer : public Renderer
	{
		
		struct TileData
		{
			UserPoint	 mPos;
			Rect			mRect;
			UserPoint	 mDxDxy;
			unsigned int mColour;
			bool			mHasTrans;
			bool			mHasColour;

			TileData(){}

			TileData(const UserPoint *inPoint,int inFlags)
				: mPos(*inPoint), mRect(inPoint[1].x, inPoint[1].y, inPoint[2].x, inPoint[2].y)
			{
				inPoint += 3;
				mHasTrans =  (inFlags & pcTile_Trans_Bit);
				if (mHasTrans)
					mDxDxy = *inPoint++;

				mHasColour = (inFlags & pcTile_Col_Bit);
				if (mHasColour)
				{
					UserPoint rg = inPoint[0];
					UserPoint ba = inPoint[1];
					mColour = ((rg.x<0 ? 0 : rg.x>1?255 : (int)(rg.x*255))) |
								 ((rg.y<0 ? 0 : rg.y>1?255 : (int)(rg.y*255))<<8) |
								 ((ba.x<0 ? 0 : ba.x>1?255 : (int)(ba.x*255))<<16) |
								 ((ba.y<0 ? 0 : ba.y>1?255 : (int)(ba.y*255))<<24);
				}
			}
		};



	public:
		
		TileRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
		~TileRenderer();
		
		bool Render(const RenderTarget &inTarget, const RenderState &inState);
		bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent);
		bool Hits(const RenderState &inState);
		void Destroy();
		
		GraphicsBitmapFill *mFill;
		Filler				 *mFiller;
		QuickVec<TileData> mTileData;
		BlendMode          mBlendMode;
	};

}


#endif
