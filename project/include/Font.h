#ifndef NME_FONT_H
#define NME_FONT_H

#include <nme/Object.h>
#include <nme/NmeCffi.h>
#include <Graphics.h>
#include <Tilesheet.h>
#include <map>
#include <string>
#include <Geom.h>
#include <ByteArray.h>

namespace nme
{

struct TextLineMetrics
{
   float ascent;
   float descent;
   float height;

   void fontToLocal(double inScale)
   {
      ascent *= inScale;
      descent *= inScale;
      height = ascent + descent;
   }

   // From text format - local coords
   float leading;

   // The horizontal components are in local coords
   float width;
   float x;
};



enum TextFormatFlags
{
   ffItalic    = 0x01,
   ffBold      = 0x02,
   ffUnderline = 0x04,
};

extern bool gNmeNativeFonts;

enum AntiAliasType { aaNormal, aaAdvanced, aaAdvancedLcd  };
enum AutoSizeMode  { asCenter, asLeft, asNone, asRight };
enum TextFormatAlign { tfaCenter, tfaJustify, tfaLeft, tfaRight};
enum GridFitType { gftNone, gftPixel, gftSubPixel };


template<typename T>
class Optional
{
public:
   Optional(const Optional &inRHS) : mVal(inRHS.mVal), mSet(inRHS.mSet) { }
   void operator = (const Optional &inRHS) { mVal = inRHS.mVal; mSet = inRHS.mSet; }
   
   Optional(const T&inVal) : mVal(inVal), mSet(false) { }
   T& operator >>(T &outRHS) { if (mSet) outRHS = mVal; return mVal; }
   T& operator=(const T&inRHS) { mVal = inRHS; mSet = true; return mVal; }
   operator T() const { return mVal; }
   T operator()(T inDefault) const { return mSet ? mVal : inDefault; }
   T &Set() { mSet=true; return mVal; }
   const T &Get() const { return mVal; }
   void Apply(Optional<T> &inRHS) const { if (mSet) inRHS=mVal; }
   void IfEquals(Optional<T> &inRHS) { if (mSet && inRHS.mSet && inRHS.mVal != mVal) mSet = false; }
   bool IsSet() const { return mSet; }

   T &write() { mSet = true; return mVal; }
   T &__Get() { return mVal; }

private:
   bool mSet;
   T mVal;
};

class TextFormat : public Object
{
public:
   TextFormat(const TextFormat &,bool inInitRef=true);
   static TextFormat *Create(bool inInitRef = true);
   static TextFormat *Default();
   static TextFormat *fromStream(class ObjectStreamIn &inStream);
   TextFormat *IncRef() { Object::IncRef(); return this; }

   NmeObjectType getObjectType() { return notTextFormat; }

   void encodeStream(class ObjectStreamOut &inStream);
   void decodeStream(class ObjectStreamIn &inStream);


   TextFormat *COW();


   Optional<TextFormatAlign>  align;
   Optional<int>           blockIndent;
   Optional<bool>          bold;
   Optional<bool>          bullet;
   Optional<uint32>        color;
   Optional<WString>  font;
   Optional<int>           indent;
   Optional<bool>          italic;
   Optional<bool>          kerning;
   Optional<int>           leading;
   Optional<int>           leftMargin;
   Optional<int>           letterSpacing;
   Optional<int>           rightMargin;
   Optional<int>           size;
   Optional<float>         outline;
   Optional<float>         outlineMiterLimit;
   Optional<int>           outlineFlags;
   Optional<QuickVec<int> >tabStops;
   Optional<WString>  target;
   Optional<bool>          underline;
   Optional<WString>  url;

   TextFormat();
   ~TextFormat();
private:
   void operator = (const TextFormat &);
};



struct CharGroup
{
   CharGroup() : mChar0(0), mFontHeight(0), mFormat(0), mFont(0), mAaType(aaNormal) { };
   ~CharGroup();
   void  Clear();
   bool  UpdateFont(double inScale,bool inNative, AntiAliasType aaType);
   void  UpdateMetrics(TextLineMetrics &ioMetrics);
   double   Height(double inFontToLocal);
   int   Chars() const { return mString.size(); }

   void ApplyFormat(TextFormat *inFormat);

   int               mChar0;
   QuickVec<wchar_t,0> mString;
   int             mFontHeight;
   unsigned int    mFlags;
   AntiAliasType   mAaType;
   TextFormat      *mFormat;
   class Font      *mFont;
};


typedef QuickVec<CharGroup *> CharGroups;

struct Line
{
   Line() { Clear(); }

   void Clear() { memset(this,0,sizeof(*this)); }
   TextLineMetrics mMetrics;
   float mY0;
   int   mChar0;
   int   mChars;
   int   mCharGroup0;
   int   mCharInGroup0;
};

typedef QuickVec<Line> Lines;


#ifdef HXCPP_JS_PRIME
typedef BufferData *FontBuffer;
#else
typedef AutoGCRoot *FontBuffer;
#endif


class FontFace
{
public:
   virtual ~FontFace() { };

   static FontFace *CreateNative(const TextFormat &inFormat,double inScale, AntiAliasType aaType);
   static FontFace *CreateFreeType(const TextFormat &inFormat,double inScale,FontBuffer inBytes, const std::string &inCombinedName);
   static FontFace *CreateCFFIFont(const TextFormat &inFormat,double inScale);

   virtual bool GetGlyphInfo(int inChar, int &outW, int &outH, int &outAdvance,
                           int &outOx, int &outOy) = 0;
   virtual void RenderGlyph(int inChar,const RenderTarget &outTarget)=0;
   virtual void UpdateMetrics(TextLineMetrics &ioMetrics)=0;
   virtual int  Height()=0;
   virtual bool IsNative() { return false; }
   virtual bool WantRGB() { return false; }

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
   static Font *Create(TextFormat &inFormat,double inScale, bool inNative, AntiAliasType aaType, bool inInitRef=true);

   NmeObjectType getObjectType() { return notFont; }
   void encodeStream(class ObjectStreamOut &inStream);
   void decodeStream(class ObjectStreamIn &inStream);


   Font *IncRef() { Object::IncRef(); return this; }

   Tile GetGlyph(int inCharacter,int &outAdvance6);

   void  UpdateMetrics(TextLineMetrics &ioMetrics);

   bool  IsNative() { return mFace && mFace->IsNative(); }

   int   Height();
private:
   Font(FontFace *inFace, int inPixelHeight, bool inInitRef);
   ~Font();


   Glyph mGlyph[128];
   std::map<int,Glyph>   mExtendedGlyph;
   QuickVec<Tilesheet *> mSheets;
   FontFace              *mFace;

   int    mPixelHeight;
   int    mCurrentSheet;
};

class FontCache
{
};

} // end namespace nme

#endif
