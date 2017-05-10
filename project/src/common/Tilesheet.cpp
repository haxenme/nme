#include <Tilesheet.h>
#include <Surface.h>
#include <algorithm>

namespace nme
{

Tilesheet::Tilesheet(int inWidth,int inHeight,PixelFormat inFormat, bool inInitRef) : Object(inInitRef)
{
   mCurrentX = 0;
   mCurrentY = 0;
   mMaxHeight = 0;
   mSheet = new SimpleSurface(inWidth,inHeight,inFormat);
   mSheet->IncRef();
}

Tilesheet::Tilesheet(Surface *inSurface,bool inInitRef) : Object(inInitRef)
{
   mCurrentX = 0;
   mCurrentY = 0;
   mMaxHeight = 0;
   mSheet = inSurface;
   if (mSheet)
      mSheet->IncRef();

}


Tilesheet::~Tilesheet()
{
   mSheet->DecRef();
}

int Tilesheet::AllocRect(int inW,int inH,float inOx, float inOy,bool inAlphaBorder)
{
   Tile tile;
   tile.mOx = inOx;
   tile.mOy = inOy;
   tile.mSurface = mSheet;

   // does it fit on the current row ?
   int cx = mCurrentX;
   if (inAlphaBorder && cx>0)
      cx++;
   int cy = mCurrentY;
   if (inAlphaBorder && cy>0)
      cy++;
   if (cx + inW <= mSheet->Width() && cy + inH < mSheet->Height())
   {
      tile.mRect = Rect(cx, cy, inW, inH);
      tile.mFRect = FRect(cx, cy, inW, inH);
      int result = mTiles.size();
      mTiles.push_back(tile);
      mCurrentX = cx+inW;
      mMaxHeight = std::max(mMaxHeight,inH+cy-mCurrentY);
      return result;
   }
   // No - go to next row
   mCurrentY += mMaxHeight;
   mCurrentX = 0;
   mMaxHeight = 0;
   if (inW>mSheet->Width() || mCurrentY + inH > mSheet->Height())
      return -1;

   tile.mRect = Rect(mCurrentX, mCurrentY, inW, inH);
   tile.mFRect = FRect(mCurrentX, mCurrentY, inW, inH);
   int result = mTiles.size();
   mTiles.push_back(tile);
   mCurrentX += inW;
   mMaxHeight = std::max(mMaxHeight,inH);
   return result;
}

int Tilesheet::addTileRect(const Rect &inRect,float inOx, float inOy)
{
   Tile tile;
   tile.mOx = inOx;
   tile.mOy = inOy;
   tile.mRect = inRect;
   tile.mFRect.x = inRect.x;
   tile.mFRect.y = inRect.y;
   tile.mFRect.w = inRect.w;
   tile.mFRect.h = inRect.h;
   tile.mSurface = mSheet;

   int result = mTiles.size();
   mTiles.push_back(tile);
   return result;
}

bool Tilesheet::IsSingleTileImage()
{
   if  (mTiles.size()!=1)
      return false;
   const Tile &tile = mTiles[0];
   if ( tile.mOx==0 && tile.mOy==0 && tile.mRect.x==0 &&  tile.mRect.y==0 &&
          tile.mRect.w==mSheet->Width() && tile.mRect.h==mSheet->Height())
   {

      #if defined(HX_LINUX) || defined(HX_MACOS) || defined(HX_WINDOWS)
      return true;
      #else
      // Only supported if we are sure texture coordinates will be (0,0) (1,1) - power of 2
      return  ! ((tile.mRect.w-1) & (tile.mRect.w)) &&
              ! ((tile.mRect.h-1) & (tile.mRect.h));
      #endif
   }
   return false;
}

void Tilesheet::encodeStream(ObjectStreamOut &inStream)
{
   inStream.add(mCurrentX);
   inStream.add(mCurrentY);
   inStream.add(mMaxHeight);
   inStream.addObject(mSheet);
   inStream.addVec(mTiles);
}


void Tilesheet::decodeStream(ObjectStreamIn &inStream)
{
   inStream.get(mCurrentX);
   inStream.get(mCurrentY);
   inStream.get(mMaxHeight);
   inStream.getObject(mSheet);
   inStream.getVec(mTiles);
   for(int i=0;i<mTiles.size();i++)
      mTiles[i].mSurface = mSheet;
}


Tilesheet *Tilesheet::fromStream(ObjectStreamIn &inStream)
{
   Tilesheet *result = new Tilesheet(0,false);
   inStream.linkAbstract(result);
   result->decodeStream(inStream);

   return result;
}




} // end namespace nme

