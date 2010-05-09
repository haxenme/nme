#ifndef NME_FONT_H
#define NME_FONT_H

#include <Object.h>
#include <Graphics.h>
#include <TileSheet.h>
#include <map>
#include <string>
#include <Geom.h>

namespace nme
{

struct TextLineMetrics
{
	float ascent;
	float descent;
	float height;
	float leading;
	float width;
	float x;
};



enum
{
	ffItalic  = 0x01,
	ffBold    = 0x02,
};


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
   T operator()(T inDefault) const { return mSet ? mVal : inDefault; }
	T &Set() { mSet=true; return mVal; }
   const T &Get() const { return mVal; }
	void Apply(Optional<T> &inRHS) const { if (mSet) inRHS=mVal; }

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

	TextFormat *COW();


   Optional<TextFormatAlign>  align;
	Optional<int>           blockIndent;
	Optional<bool>          bold;
	Optional<bool>          bullet;
	Optional<uint32>        color;
	Optional<std::wstring>  font;
	Optional<int>           indent;
	Optional<bool>          italic;
	Optional<bool>          kerning;
	Optional<int>           leading;
	Optional<int>           leftMargin;
	Optional<int>           letterSpacing;
	Optional<int>           rightMargin;
	Optional<int>           size;
	Optional<QuickVec<int> >tabStops;
	Optional<std::wstring>  target;
	Optional<bool>          underline;
	Optional<std::wstring>  url;

	TextFormat();
	~TextFormat();
};



struct CharGroup
{
	void  Clear();
	bool  UpdateFont(double inScale,GlyphRotation inRotation,bool inNative);
	void  UpdateMetrics(TextLineMetrics &ioMetrics);
	int   Height();
	int   Chars() { return mString.size(); }

	void ApplyFormat(TextFormat *inFormat);

	int               mChar0;
	QuickVec<wchar_t,0> mString;
	int             mFontHeight;
	bool            mBeginParagraph;
	TextFormat      *mFormat;
	class Font      *mFont;
};


typedef QuickVec<CharGroup> CharGroups;

struct Line
{
	Line() { Clear(); }

	void Clear() { memset(this,0,sizeof(*this)); }
	TextLineMetrics mMetrics;
	int mY0;
   int mChar0;
	int mChars;
	int mCharGroup0;
	int mCharInGroup0;
};

typedef QuickVec<Line> Lines;




class FontFace
{
public:
	virtual ~FontFace() { };

	static FontFace *CreateNative(const TextFormat &inFormat,double inScale);
	static FontFace *CreateFreeType(const TextFormat &inFormat,double inScale);

	virtual bool GetGlyphInfo(int inChar, int &outW, int &outH, int &outAdvance,
									int &outOx, int &outOy) = 0;
	virtual void RenderGlyph(int inChar,const RenderTarget &outTarget)=0;
	virtual void UpdateMetrics(TextLineMetrics &ioMetrics)=0;
	virtual int  Height()=0;
	virtual bool IsNative() { return false; }

};


class Font : public Object
{
   struct Glyph
   {
		Glyph() : sheet(-1), tile(-1) { }

	   int sheet;
	   int tile;
		int advance;
	};

public:
   static Font *Create(TextFormat &inFormat,double inScale,GlyphRotation inRot, bool inNative,bool inInitRef=true);

	Font *IncRef() { Object::IncRef(); return this; }

   Tile GetGlyph(int inCharacter,int &outAdvance);

	void  UpdateMetrics(TextLineMetrics &ioMetrics);

	bool  IsNative() { return mFace && mFace->IsNative(); }

	int   Height();
private:
   Font(FontFace *inFace, int inPixelHeight, GlyphRotation inRotation,bool inInitRef);
	~Font();


	Glyph mGlyph[128];
	std::map<int,Glyph>   mExtendedGlyph;
   QuickVec<Tilesheet *> mSheets;
	FontFace              *mFace;

	int    mPixelHeight;
	int    mCurrentSheet;
	GlyphRotation mRotation;
};

class FontCache
{
};

} // end namespace nme

#endif
