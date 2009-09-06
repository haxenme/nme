#ifndef FONT_H
#define FONT_H

#include <Object.h>
#include <Graphics.h>
#include <TileSheet.h>
#include <map>

enum AntiAliasType { aaAdvanced, aaNormal };
enum AutoSizeMode  { asCenter, asLeft, asNone, asRight };
enum TextFormatAlign { tfaCenter, tfaJustify, tfaLeft, tfaRight};
enum GridFitType { gftNone, gftPixel, gftSubPixel };


template<typename T>
class Optional
{
public:
	Optional(const T&inVal) : mVal(inVal), mSet(false) { }
   T& operator >>(T &outRHS) { if (mSet) outRHS = mVal; return mVal; }
   T& operator=(const T&inRHS) { mVal = inRHS; mSet = true; return mVal; }
   operator T() const { return mVal; }

private:
	bool mSet;
	T mVal;
};

class TextFormat : public Object
{
public:
	static TextFormat *Create(bool inInitRef = true);
	static TextFormat *Default();
	TextFormat *IncRef() { Object::IncRef(); return this; }

	TextFormat &COW();


   Optional<TextFormatAlign>  align;
	Optional<int>           blockIndent;
	Optional<bool>          bold;
	Optional<bool>          bullet;
	Optional<ARGB>          color;
	Optional<std::wstring>  font;
	Optional<int>           indent;
	Optional<bool>          italic;
	Optional<bool>          kerning;
	Optional<int>           leading;
	Optional<int>           leftMargin;
	Optional<int>           letterSpacing;
	Optional<int>           rightMargin;
	Optional<int>           size;
	Optional<QuickVec<int>> tabStops;
	Optional<std::wstring>  target;
	Optional<bool>          underline;
	Optional<std::wstring>  url;

	TextFormat();
	~TextFormat();
};


struct FT_FaceRec_;

class Font : public Object
{
   struct Glyph
   {
		Glyph() : sheet(-1), tile(-1) { }

	   int sheet;
	   int tile;
	};

public:
   static Font *Create(TextFormat &inFormat,double inScale,bool inInitRef=true);

	Font *IncRef() { Object::IncRef(); return this; }

   Tile GetGlyph(int inCharacter);

private:
   Font(FT_FaceRec_ *inFace,int inH, bool inInitRef);
	~Font();


	Glyph mGlyph[128];
	std::map<int,Glyph>   mExtendedGlyph;
   QuickVec<TileSheet *> mSheets;
	FT_FaceRec_           *mFace;

	int  mPixelHeight;
	int  mCurrentSheet;
};

class FontCache
{
};


#endif
