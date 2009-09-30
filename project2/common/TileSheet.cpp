#include <TileSheet.h>
#include <Surface.h>
#include <algorithm>


TileSheet::TileSheet(int inWidth,int inHeight,PixelFormat inFormat, bool inInitRef) : Object(inInitRef)
{
	mCurrentX = 0;
	mCurrentY = 0;
	mMaxHeight = 0;
	mSheet = new SimpleSurface(inWidth,inHeight,inFormat);

}

TileSheet::~TileSheet()
{
	mSheet->DecRef();
}

int TileSheet::AllocRect(int inW,int inH,float inOx, float inOy)
{
	Tile tile;
	tile.mOx = inOx;
	tile.mOy = inOy;
	tile.mSurface = mSheet;

	// does it fit on the current row ?
	if (mCurrentX + inW <= mSheet->Width() && mCurrentY + inH < mSheet->Height())
	{
		tile.mRect = Rect(mCurrentX, mCurrentY, inW, inH);
		int result = mTiles.size();
		mTiles.push_back(tile);
		mCurrentX += inW;
		mMaxHeight = std::max(mMaxHeight,inH);
		return result;
	}
	// No - go to next row
	mCurrentY += mMaxHeight;
	mCurrentX = 0;
	mMaxHeight = 0;
	if (inW>mSheet->Width() || mCurrentY + inH > mSheet->Height())
		return -1;

	tile.mRect = Rect(mCurrentX, mCurrentY, inW, inH);
	int result = mTiles.size();
	mTiles.push_back(tile);
	mCurrentX += inW;
	mMaxHeight = std::max(mMaxHeight,inH);
	return result;
}


