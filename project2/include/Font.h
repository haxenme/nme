#ifndef FONT_H
#define FONT_H

#include <Graphics.h>

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
   operator T() { return mVal; }

private:
	bool mSet;
	T mVal;
};

class TextFormat 
{
public:
	static TextFormat *Create(bool inInitRef = true);
	static TextFormat *Default();
	TextFormat *IncRef();
	void DecRef();

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

protected:
	int mRefCount;
	TextFormat();
	~TextFormat();
};



class Font
{
public:
   static Font *Create(TextFormat &inFormat);
   void DecRef();
	Font *IncRef();


   double      mPixelHeight;
	std::string mFace;

private:
	Font();
	~Font();
	int mRefCount;
};

class FontCache
{
};


#endif
