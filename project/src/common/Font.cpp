#include <Font.h>
#include <Utils.h>
#include <Surface.h>
#include <map>

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
// Include neko glue....
#define NEKO_COMPATIBLE
#endif
#include <nme/NmeCffi.h>
#include <Utils.h>

#if defined(HX_WINDOWS)
#define strcasecmp stricmp
#endif

#ifdef HXCPP_JS_PRIME
#include <zlib.h>

extern int gSansFullSize;
extern int gSansCompressedSize;
extern const unsigned char *gSansData;

extern int gSerifFullSize;
extern int gSerifCompressedSize;
extern const unsigned char *gSerifData;

extern int gMonospaceFullSize;
extern int gMonospaceCompressedSize;
extern const unsigned char *gMonospaceData;


#endif

namespace nme
{

bool gNmeNativeFonts = true;

extern std::string GetFreeTypeFaceName(FontBuffer inBytes);


// --- CFFI font delegates to haxe to get the glyphs -----

static int _id_bold=0;
static int _id_name=0;
static int _id_italic=0;
static int _id_height=0;
static int _id_ascent=0;
static int _id_descent=0;
static int _id_isRGB=0;

static int _id_getGlyphInfo=0;
static int _id_renderGlyphInternal=0;
static int _id_width=0;
static int _id_advance=0;
static int _id_offsetX=0;
static int _id_offsetY=0;

class CFFIFont : public FontFace
{
public:
   CFFIFont(value inHandle) : mHandle(inHandle)
   {
      mAscent = val_number( val_field(inHandle, _id_ascent) );
      mDescent = val_number( val_field(inHandle, _id_descent) );
      mHeight = val_number( val_field(inHandle, _id_height) );
      mIsRGB = val_bool( val_field(inHandle, _id_isRGB) );
   }

   bool WantRGB() { return true; }

   bool GetGlyphInfo(int inChar, int &outW, int &outH, int &outAdvance,
                           int &outOx, int &outOy)
   {
      value result = val_ocall1( mHandle.get(), _id_getGlyphInfo, alloc_int(inChar) );
      if (!val_is_null(result))
      {
         outW = val_number( val_field(result, _id_width) );
         outH = val_number( val_field(result, _id_height) );
         outAdvance = (int)(val_number( val_field(result, _id_advance) )) << 6;
         outOx = val_number( val_field(result, _id_offsetX) );
         outOy = val_number( val_field(result, _id_offsetY) );
         return true;
      }
      return false;
   }

   void RenderGlyph(int inChar,const RenderTarget &outTarget)
   {
      value glyphBmp = val_ocall1(mHandle.get(), _id_renderGlyphInternal, alloc_int(inChar) );
      Surface *surface = 0;
      if (AbstractToObject(glyphBmp,surface) )
      {
         surface->BlitTo(outTarget, Rect(0,0,surface->Width(), surface->Height()),
                         outTarget.mRect.x, outTarget.mRect.y, bmNormal, 0 );
      }
   }

   void UpdateMetrics(TextLineMetrics &ioMetrics)
   {
      ioMetrics.ascent = std::max( ioMetrics.ascent, (float)mAscent);
      ioMetrics.descent = std::max( ioMetrics.descent, (float)mDescent);
      ioMetrics.height = std::max( ioMetrics.height, (float)mHeight);
   }
   int Height()
   {
      return mHeight;
   }


   AutoGCRoot mHandle;
   float mAscent;
   float mDescent;
   int   mHeight;
   bool  mIsRGB;
};

AutoGCRoot *sCFFIFontFactory = 0;

value nme_font_set_factory(value inFactory)
{
   if (!sCFFIFontFactory)
   {
      sCFFIFontFactory = new AutoGCRoot(inFactory);
      _id_bold = val_id("bold");
      _id_name = val_id("name");
      _id_italic = val_id("italic");
      _id_height = val_id("height");
      _id_ascent = val_id("ascent");
      _id_descent = val_id("descent");
      _id_isRGB = val_id("isRGB");

      _id_getGlyphInfo = val_id("getGlyphInfo");
      _id_renderGlyphInternal = val_id("renderGlyphInternal");
      _id_width = val_id("width");
      _id_advance = val_id("advance");
      _id_offsetX = val_id("offsetX");
      _id_offsetY = val_id("offsetY");
   }
   return alloc_null();
}

DEFINE_PRIM(nme_font_set_factory,1)

FontFace *FontFace::CreateCFFIFont(const TextFormat &inFormat,double inScale)
{
   if (!sCFFIFontFactory)
      return 0;

   value format = alloc_empty_object();
   alloc_field(format, _id_bold, alloc_bool( inFormat.bold ) );
   alloc_field(format, _id_name, alloc_wstring( inFormat.font.Get().c_str() ) );
   alloc_field(format, _id_italic, alloc_bool( inFormat.italic ) );
   alloc_field(format, _id_height, alloc_float( (int )(inFormat.size*inScale + 0.5) ) );

   value result = val_call1( sCFFIFontFactory->get(), format );

   if (val_is_null(result))
      return 0;

   return new CFFIFont(result);
}


// --- Font ----------------------------------------------------------------


Font::Font(FontFace *inFace, int inPixelHeight, bool inInitRef) :
     Object(inInitRef), mFace(inFace), mPixelHeight(inPixelHeight)
{
   mCurrentSheet = -1;
}


Font::~Font()
{
   for(int i=0;i<mSheets.size();i++)
      mSheets[i]->DecRef();
   if (mFace) delete mFace;
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
            adv = mPixelHeight<<6;
            use_default = true;
         }
         else
         {
            Tile result = GetGlyph('?',outAdvance);
            glyph = mGlyph['?'];
            return result;
         }
      }

      int orig_w = gw;
      int orig_h = gh;

      while(1)
      {
         // Allocate new sheet?
         if (mCurrentSheet<0)
         {
            int rows = mPixelHeight > 127 ? 1 : mPixelHeight > 63 ? 2 : mPixelHeight>31 ? 4 : 5;
            int h = 4;
            while(h<orig_h*rows)
               h*=2;
            int w = h;
            while(w<orig_w)
               w*=2;
            PixelFormat pf = mFace->WantRGB() ? pfBGRA : pfAlpha;
            Tilesheet *sheet = new Tilesheet(w,h,pf,true);
            sheet->GetSurface().Clear(0);
            mCurrentSheet = mSheets.size();
            mSheets.push_back(sheet);
         }

         int tid = mSheets[mCurrentSheet]->AllocRect(gw,gh,ox,oy,true);
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

double CharGroup::Height(double inFontToLocal)
  { return inFontToLocal * (mFont ? mFont->Height() : 12); }


// --- Create font from TextFormat ----------------------------------------------------





struct FontInfo
{
   FontInfo(const TextFormat &inFormat,double inScale)
   {
      allowNative = gNmeNativeFonts;
      name = inFormat.font;
      height = (int )(inFormat.size*inScale + 0.5);
      flags = 0;
      if (inFormat.bold)
         flags |= ffBold;
      if (inFormat.italic)
         flags |= ffItalic;
      if (inFormat.underline)
         flags |= ffUnderline;
   }

   bool operator<(const FontInfo &inRHS) const
   {
      if (allowNative != inRHS.allowNative) return allowNative;
      if (name < inRHS.name) return true;
      if (name > inRHS.name) return false;
      if (height < inRHS.height) return true;
      if (height > inRHS.height) return false;
      return flags < inRHS.flags;
   }
   WString      name;
   bool         allowNative;
   int          height;
   unsigned int flags;
};

const char *RemapFontName(const char *inName)
{
   if (!strcasecmp(inName,"times.ttf") ||
       !strcasecmp(inName,"serif") ||
       !strcasecmp(inName,"\"serif\"") ||
       !strcasecmp(inName,"times"))
      return "_serif"; 
   else if (!strcasecmp(inName,"arial.ttf") ||
            !strcasecmp(inName,"arial") ||
            !strcasecmp(inName,"\"sans-serif\"") ||
            !strcasecmp(inName,"sans-serif") )
      return "_sans"; 
   else if (!strcasecmp(inName,"_typewriter") ||
            !strcasecmp(inName,"courier.ttf") ||
            !strcasecmp(inName,"monospace") ||
            !strcasecmp(inName,"\"monospace\"") ||
            !strcasecmp(inName,"courier"))
      return "_monospace"; 

   return 0;
}



typedef std::map<FontInfo, Font *> FontMap;
FontMap sgFontMap;

#ifdef HXCPP_JS_PRIME
BufferData *decompressFontData(int srcLen, int destLen, const unsigned char *inData)
{
   BufferData *data = new BufferData();
   data->IncRef();
   data->data.resize(destLen);

   z_stream z;
   memset(&z,0,sizeof(z_stream));
   int err = 0;
   int flush = Z_NO_FLUSH;
   if ( inflateInit2(&z,MAX_WBITS) != Z_OK )
      val_throw(alloc_string("bad inflateInit"));

   z.next_in = (Bytef*)inData;
   z.avail_in = srcLen;

   z.next_out = (Bytef*)&data->data[0];
   z.avail_out = data->data.size();
   int code = 0;
   if( (code = ::inflate(&z,flush)) < 0 )
   {
       inflateEnd(&z);
       val_throw( alloc_string("bad inflate") );
   }

   inflateEnd(&z);

   return data;
}
#endif




typedef std::map<std::string, FontBuffer> FontBytesMap;

FontBytesMap sgRegisteredFonts;
static std::string registerNorm(const std::string &inName)
{
   std::string result = inName;
   int len = inName.size();
   const char *p = inName.c_str();
   for(int i=0;i<len;i++)
      result[i] = ::tolower(p[i]);
   return result;
}

Font *Font::Create(TextFormat &inFormat,double inScale,bool inNative,bool inInitRef)
{
   bool native = inNative && gNmeNativeFonts;

   FontInfo info(inFormat,inScale);

   Font *font = 0;
   FontMap::iterator fit = sgFontMap.find(info);
   if (fit!=sgFontMap.end())
   {
      font = fit->second;
      if (inInitRef)
         font->IncRef();
      return font;
   }

   std::string fontName(WideToUTF8(inFormat.font));

   FontFace *face = 0;
   
   int pass0 = inFormat.bold || inFormat.italic ? 0 : 1;
    
   for(int pass=pass0;pass<3;pass++)
   {
      std::string seekName = fontName;
      if (pass==0)
      {
          if (inFormat.bold)
              seekName += " Bold";
          if (inFormat.italic)
              seekName += " Italic";
      }
      else if (pass==2)
      {
         const char *remappedFont = RemapFontName(fontName.c_str());
         if (!remappedFont)
            break;
         seekName = remappedFont;
      }

      std::string norm = registerNorm(seekName);
      FontBuffer bytes = 0;
      FontBytesMap::iterator fbit = sgRegisteredFonts.find(norm);

      if (fbit!=sgRegisteredFonts.end())
      {
         bytes = fbit->second;
         //printf("Registered!\n");
      }


      if (!bytes)
      {
         ByteArray resource(seekName.c_str());
         if (resource.Ok())
         {
            #ifdef HXCPP_JS_PRIME
            sgRegisteredFonts[norm] = val_to_buffer( resource.mValue );
            sgRegisteredFonts[norm]->IncRef();
            #else
            sgRegisteredFonts[norm] = new AutoGCRoot( resource.mValue );
            #endif

            fbit = sgRegisteredFonts.find(norm);
            bytes = fbit->second;
          //  printf("Found!\n");
         }
         //else
         //   printf("No resource\n");
      }

      #ifdef HXCPP_JS_PRIME
      if (!bytes)
      {
         if (norm=="_sans")
            bytes = decompressFontData( gSansCompressedSize, gSansFullSize, gSansData );
         else if (norm=="_serif")
            bytes = decompressFontData( gSerifCompressedSize, gSerifFullSize, gSerifData );
         else if (norm=="_monospace")
            bytes = decompressFontData( gMonospaceCompressedSize, gMonospaceFullSize, gMonospaceData );

         if (bytes)
            sgRegisteredFonts[norm] = bytes;
      }
      #endif

      if (bytes)
      {
         face = FontFace::CreateFreeType(inFormat,inScale,bytes,pass==0 ? seekName : "");
         if (face)
            break;
      }
   }

   if (!face)
      face = FontFace::CreateCFFIFont(inFormat,inScale);

#ifndef HX_WINRT
   if (native && !face)
      face = FontFace::CreateNative(inFormat,inScale);
#endif

   if (!face)
      face = FontFace::CreateFreeType(inFormat,inScale,NULL,"");

#ifndef HX_WINRT
   if (!native && !face)
      face = FontFace::CreateNative(inFormat,inScale);
#endif
   if (!face)
   {
      //printf("Missing face : %s\n", fontName.c_str() );
      TextFormat defaultFormat = inFormat;
      defaultFormat.font = UTF8ToWide("_sans");
      return Create(defaultFormat, inScale, inNative, inInitRef);
       return 0;
   }

   font =  new Font(face,info.height,inInitRef);
   // Store for Ron ...
   font->IncRef();
   sgFontMap[info] = font;

   // Clear out any old fonts
   for (FontMap::iterator fit = sgFontMap.begin(); fit!=sgFontMap.end();)
   {
      if (fit->second->GetRefCount()==1)
      {
         fit->second->DecRef();
         FontMap::iterator next = fit;
         next++;
         sgFontMap.erase(fit);
         fit = next;
      }
      else
         ++fit;
   }
   
   return font;
}

void Font::encodeStream(ObjectStreamOut &inStream)
{
   printf("Font::encodeStream\n");
}
void Font::decodeStream(ObjectStreamIn &inStream)
{
   printf("Font::decodeStream\n");
}


void nmeRegisterFont(const std::string &inName, FontBuffer inData)
{
   sgRegisteredFonts[registerNorm(inName)] = inData;
}

FontBuffer nmeGetRegisteredFont(const std::string &inName)
{
   return sgRegisteredFonts[registerNorm(inName)];
}

value nme_font_register_font(value inFontName, value inBytes)
{
   std::string name = valToStdString(inFontName);
   #ifdef HXCPP_JS_PRIME
   FontBuffer bytes = val_to_buffer(inBytes);
   bytes->IncRef();
   #else
   AutoGCRoot *bytes = new AutoGCRoot(inBytes);
   #endif
   sgRegisteredFonts[ registerNorm(name) ] = bytes;

   std::string faceName = registerNorm( GetFreeTypeFaceName(bytes) );
   if (faceName!="")
   {
      //printf("faceName alias : %s\n", faceName.c_str());
      if (sgRegisteredFonts.find(faceName)==sgRegisteredFonts.end())
         sgRegisteredFonts[faceName] = bytes;
   }

   return alloc_null();
}
DEFINE_PRIM(nme_font_register_font,2)



value nme_font_get_use_native()
{
   return alloc_bool(gNmeNativeFonts);
}
DEFINE_PRIM(nme_font_get_use_native,0)




value nme_font_set_use_native(value inUse)
{
   gNmeNativeFonts = val_bool(inUse);
   return inUse;
}
DEFINE_PRIM(nme_font_set_use_native,1)




} // end namespace nme

