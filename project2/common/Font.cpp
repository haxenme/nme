#include <Font.h>
#include <Utils.h>
#include <map>



Font::Font(FontFace *inFace, int inPixelHeight, bool inInitRef) :
	  Object(inInitRef), mFace(inFace), mPixelHeight(inPixelHeight)
{
	mCurrentSheet = -1;
}


Font::~Font()
{
	delete mFace;
	for(int i=0;i<mSheets.size();i++)
		mSheets[i]->DecRef();
}



Tile Font::GetGlyph(int inCharacter,int &outAdvance)
{
	bool use_default = false;
   Glyph &glyph = inCharacter < 128 ? mGlyph[inCharacter] : mExtendedGlyph[inCharacter];
	if (glyph.sheet<0)
	{
		int gw,gh,adv,ox,oy;
		bool ok = mFace->GetGlyphInfo(inCharacter,gw,gh,adv,ox,oy);
		if (!ok)
		{
			if (inCharacter=='?')
			{
				gw = mPixelHeight;
				gh = mPixelHeight;
				ox = oy = 0;
				adv = mPixelHeight;
				use_default = true;
			}
			else
			{
				Tile result = GetGlyph('?',outAdvance);
            mGlyph[inCharacter] = mGlyph['?'];
				return result;
			}
		}

		while(1)
		{
			// Allocate new sheet?
			if (mCurrentSheet<0)
			{
				int rows = mPixelHeight > 128 ? 1 : mPixelHeight > 64 ? 2 : mPixelHeight>32 ? 4 : 5;
				int h = 4;
				while(h<mPixelHeight*rows)
					h*=2;
				int w = h;
				while(w<gw)
					w*=2;
            TileSheet *sheet = new TileSheet(w,h,true);
				mCurrentSheet = mSheets.size();
				mSheets.push_back(sheet);
			}

			int tid = mSheets[mCurrentSheet]->AllocRect(gw,gh,ox,oy);
			if (tid>=0)
			{
		      glyph.sheet = mCurrentSheet;
				glyph.tile = tid;
				glyph.advance = adv;
				break;
			}

			// Need new sheet...
			mCurrentSheet = -1;
		}
      // Now fill rect...
      Tile tile = mSheets[glyph.sheet]->GetTile(glyph.tile);
      // SharpenText(bitmap);
      RenderTarget target = tile.mSurface->BeginRender(tile.mRect);
		if (use_default)
		{
			for(int y=0; y<target.mRect.h; y++)
			{
            uint32  *dest = (uint32 *)target.Row(y + target.mRect.y) + target.mRect.x;
			   for(int x=0; x<target.mRect.w; x++)
					*dest++ = 0xffffffff;
			}
		}
		else
		   mFace->RenderGlyph(inCharacter,target);
      tile.mSurface->EndRender();
		outAdvance = glyph.advance;
      return tile;
	}

	outAdvance = glyph.advance;
   return mSheets[glyph.sheet]->GetTile(glyph.tile);
}


void  Font::UpdateMetrics(TextLineMetrics &ioMetrics)
{
   if (mFace)
		mFace->UpdateMetrics(ioMetrics);
}

int Font::Height()
{
	if (!mFace) return 12;
	return mFace->Height();
}


// --- CharGroup ---------------------------------------------

void  CharGroup::UpdateMetrics(TextLineMetrics &ioMetrics)
{
   if (mFont)
		mFont->UpdateMetrics(ioMetrics);
}

int CharGroup::Height()
{ return mFont ? mFont->Height() : 12; }


// --- Create font from TextFormat ----------------------------------------------------





struct FontInfo
{
	FontInfo(const TextFormat &inFormat,double inScale)
	{
		name = inFormat.font;
		height = (int )(inFormat.size*inScale + 0.5);
		flags = 0;
		if (inFormat.bold)
			flags |= ffBold;
		if (inFormat.italic)
			flags |= ffItalic;
	}

	bool operator<(const FontInfo &inRHS) const
	{
		if (name < inRHS.name) return true;
		if (name > inRHS.name) return false;
		if (height < inRHS.height) return true;
		if (height > inRHS.height) return false;
		return flags < inRHS.flags;
	}
   std::wstring name;
	int          height;
	unsigned int flags;
};


typedef std::map<FontInfo, FontFace *> FaceMap;
FaceMap sgFaceMap;

Font *Font::Create(TextFormat &inFormat,double inScale,bool inInitRef)
{
	FontInfo info(inFormat,inScale);

	FontFace *face = 0;
	FaceMap::iterator fit = sgFaceMap.find(info);
	if (fit==sgFaceMap.end())
	{
		face = FontFace::CreateNative(inFormat,inScale);
		if (!face)
		   face = FontFace::CreateFreeType(inFormat,inScale);
		if (!face)
			return 0;
		sgFaceMap[info] = face;
	}
	else
		face = fit->second;

	return new Font(face,info.height,inInitRef);
}


