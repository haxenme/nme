#ifndef TILESHEET_H
#define TILESHEET_H

#include <Graphics.h>
#include <Object.h>

struct Tile
{
	float   mOx;
	float   mOy;
	Rect    mRect;
	Surface *mSurface;
};

class TileSheet : public Object
{
public:
   TileSheet(int inWidth,int inHeight,PixelFormat inFormat,bool inInitRef=false);
	TileSheet *IncRef() { Object::IncRef(); return this; }

	int AllocRect(int inW,int inH,float inOx = 0, float inOY = 0);
	const Tile &GetTile(int inID) { return mTiles[inID]; }
	Surface &GetSurface() { return *mSheet; }

private:
	~TileSheet();

	int  mCurrentX;
	int  mCurrentY;
	int  mMaxHeight;

	QuickVec<Tile> mTiles;
	Surface        *mSheet;
};



#endif
