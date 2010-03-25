#include <Font.h>
#include <Utils.h>
#include <Surface.h>
#include <map>

namespace nme
{


Font::Font(FontFace *inFace, int inPixelHeight, GlyphRotation inRotation,bool inInitRef) :
     Object(inInitRef), mFace(inFace), mPixelHeight(inPixelHeight)
{
	mRotation = inRotation;
   mCurrentSheet = -1;
}


Font::~Font()
{
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

		int orig_w = gw;
		int orig_h = gh;
		switch(mRotation)
		{
			case gr90:
			   std::swap(gw,gh);
			   std::swap(ox,oy);
				oy = -gh-oy;
				break;
			case gr180:
				ox = -gw-ox;
				oy = -gh-oy;
				break;
			case gr270:
			   std::swap(gw,gh);
			   std::swap(ox,oy);
				ox = -gw-ox;
				break;
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
            while(w<orig_w)
               w*=2;
		      if (mRotation!=gr0 && mRotation!=gr180)
					std::swap(w,h);
            Tilesheet *sheet = new Tilesheet(w,h,pfAlpha,true);
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
            uint8  *dest = (uint8 *)target.Row(y + target.mRect.y) + target.mRect.x;
            for(int x=0; x<target.mRect.w; x++)
               *dest++ = 0xff;
         }
      }
      else if (mRotation==gr0)
         mFace->RenderGlyph(inCharacter,target);
		else
		{
			SimpleSurface *buf = new SimpleSurface(orig_w,orig_h,pfAlpha,true);
			buf->IncRef();
			{
			AutoSurfaceRender renderer(buf);
         mFace->RenderGlyph(inCharacter,renderer.Target());
			}

         const uint8  *src;
			for(int y=0; y<target.mRect.h; y++)
         {
            uint8  *dest = (uint8 *)target.Row(y + target.mRect.y) + target.mRect.x;

				switch(mRotation)
				{
					case gr90:
						src = buf->Row(0) + buf->Width() -1 - y;
            		for(int x=0; x<target.mRect.w; x++)
						{
							*dest++ = *src;
							src += buf->GetStride();
						}
						break;
					case gr180:
						src = buf->Row(buf->Height()-1-y) + buf->Width() -1;
            		for(int x=0; x<target.mRect.w; x++)
							*dest++ = *src--;
						break;
					case gr270:
						src = buf->Row(buf->Height()-1) + y;
            		for(int x=0; x<target.mRect.w; x++)
						{
							*dest++ = *src;
							src -= buf->GetStride();
						}
						break;
				}
			}
			buf->DecRef();
		}

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
   FontInfo(const TextFormat &inFormat,double inScale,GlyphRotation inRotation,bool inNative)
   {
      name = inFormat.font;
      height = (int )(inFormat.size*inScale + 0.5);
      flags = 0;
      if (inFormat.bold)
         flags |= ffBold;
      if (inFormat.italic)
         flags |= ffItalic;
		rotation = inRotation;
   }

   bool operator<(const FontInfo &inRHS) const
   {
      if (name < inRHS.name) return true;
      if (name > inRHS.name) return false;
      if (height < inRHS.height) return true;
      if (height > inRHS.height) return false;
      if (native < inRHS.native) return true;
      if (native > inRHS.native) return false;
      if (rotation < inRHS.rotation) return true;
      if (rotation > inRHS.rotation) return false;
      return flags < inRHS.flags;
   }
   std::wstring name;
   bool         native;
   int          height;
   unsigned int flags;
	GlyphRotation rotation;
};


typedef std::map<FontInfo, Font *> FontMap;
FontMap sgFontMap;

Font *Font::Create(TextFormat &inFormat,double inScale,GlyphRotation inRotation,bool inNative,bool inInitRef)
{
   FontInfo info(inFormat,inScale,inRotation,inNative);

   Font *font = 0;
   FontMap::iterator fit = sgFontMap.find(info);
   if (fit!=sgFontMap.end())
   {
      font = fit->second;
      if (inInitRef)
         font->IncRef();
      return font;
   }


   FontFace *face = 0;

        // TODO: Native iPhone font
        #ifndef IPHONE
   if (inNative)
      face = FontFace::CreateNative(inFormat,inScale);
        #endif
   if (!face)
      face = FontFace::CreateFreeType(inFormat,inScale);
        #ifndef IPHONE
   if (!face && !inNative)
      face = FontFace::CreateNative(inFormat,inScale);
        #endif
   if (!face)
        return 0;

   font =  new Font(face,info.height,inRotation,inInitRef);
   // Store for Ron ...
   font->IncRef();
   sgFontMap[info] = font;
   return font;
}


} // end namespace nme

