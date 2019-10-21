#include <nme/NmeCffi.h>

#include <Font.h>
#include <Utils.h>
#include <map>

#include <Utils.h>

#if defined(HX_WINRT) && defined(__cplusplus_winrt)
#define NOMINMAX
#include <dwrite.h>
#define generic userGeneric
#endif

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_BITMAP_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H

#ifdef NME_TOOLKIT_BUILD
#include <ftoutln.h>
#include <ftstroke.h>
#else
#include <freetype/ftoutln.h>
#endif

#ifdef ANDROID
#include <android/log.h>
#endif

#ifdef WEBOS
#include "PDL.h"
#endif

#ifndef HX_WINDOWS
#ifndef EPPC
#include <dirent.h>
#include <sys/stat.h>
#endif
#endif

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
#define NOMINMAX
#include <windows.h>
#include <tchar.h>
#endif

#include "ByteArray.h"

#define NME_FREETYPE_FLAGS  (FT_LOAD_FORCE_AUTOHINT|FT_LOAD_DEFAULT)

#define NME_OUTLINE_END_SQUARE 0x10
#define NME_OUTLINE_EDGE_BEVEL 0x20
#define NME_OUTLINE_EDGE_MITER 0x40

namespace nme
{

FT_Library sgLibrary = 0;


class FreeTypeFont : public FontFace
{
   void* mBuffer;
   FT_Face  mFace;
   uint32 mTransform;
   int    mPixelHeight;
   bool   stroked;
   int    pad;
   FT_Stroker stroker;

public:
   //  inOutline in 64th of a pixel...
   //  inOutlineMiter in 16.16 format
   FreeTypeFont(FT_Face inFace, int inPixelHeight,
                int inOutline, int inOutlineFlags, unsigned int inOutlineMiter,
                int inTransform, void* inBuffer) :
     mFace(inFace), mPixelHeight(inPixelHeight),
     mTransform(inTransform), mBuffer(inBuffer)
   {
      stroked = inOutline>0;
      pad = 0;
      if (stroked)
      {
         FT_Stroker_New(sgLibrary, &stroker);
         //  64th of a pixel...
         FT_Stroker_LineCap cap = (inOutlineFlags&NME_OUTLINE_END_SQUARE) ? FT_STROKER_LINECAP_SQUARE :
                                  FT_STROKER_LINECAP_ROUND;
         FT_Stroker_LineJoin miter = (inOutlineFlags&NME_OUTLINE_EDGE_MITER) ? FT_STROKER_LINEJOIN_MITER :
                     (inOutlineFlags&NME_OUTLINE_EDGE_BEVEL) ? FT_STROKER_LINEJOIN_BEVEL :
                     FT_STROKER_LINEJOIN_ROUND;
         FT_Stroker_Set(stroker, inOutline, cap, miter, inOutlineMiter);
         pad = (inOutline+63)>>6;
      }
   }


   ~FreeTypeFont()
   {
      if (stroked)
         FT_Stroker_Done(stroker);

      FT_Done_Face(mFace);
      if (mBuffer) free(mBuffer);
   }

   bool LoadBitmap(int inChar,bool andRender=true)
   {
      int idx = FT_Get_Char_Index( mFace, inChar );

      int renderFlags = FT_LOAD_DEFAULT;
      #ifndef EMSCRIPTEN
      // There is a bug on the proto-types of AF_WritingSystemClass this might need fixing
      //if (!(mTransform & (ffItalic|ffBold) ))
         renderFlags |= FT_LOAD_FORCE_AUTOHINT;
      #endif


      int err = FT_Load_Glyph( mFace, idx, renderFlags  );
      if (err)
         return false;

      bool emboldened = false;
      if (mTransform & ffItalic)
      {
         if ( mFace->glyph->format == FT_GLYPH_FORMAT_OUTLINE )
         {
            FT_Outline*  outline = &mFace->glyph->outline;

            FT_Matrix    transform;
            transform.xx = 0x10000L;
            transform.yx = 0x00000L;
            transform.xy = 0x06000L;
            transform.yy = 0x10000L;

            FT_Outline_Transform( outline, &transform );
         }
      }

      if (mTransform & ffBold)
      {
         if ( mFace->glyph->format == FT_GLYPH_FORMAT_OUTLINE )
         {
            emboldened = true;
            FT_Outline*  outline = &mFace->glyph->outline;
            FT_Outline_Embolden( outline, 1<<6 );
         }
      }


      FT_Render_Mode mode = FT_RENDER_MODE_NORMAL;
      // mode = FT_RENDER_MODE_MONO;
      //if (mFace->glyph->format != FT_GLYPH_FORMAT_BITMAP)
      if (andRender)
      {
         err = FT_Render_Glyph( mFace->glyph, mode );
         if (err)
            return false;

         if (mTransform & ffBold)
         {
            if ( mFace->glyph->format != FT_GLYPH_FORMAT_OUTLINE && !emboldened)
            {
               FT_GlyphSlot_Own_Bitmap(mFace->glyph);
               FT_Bitmap_Embolden(sgLibrary, &mFace->glyph->bitmap, 1<<6, 0);
            }
         }
      }

      return true;
   }

   int getUnderlineOffset() { return 1; }
   int getUnderlineHeight() { return getUnderlineOffset(); }


   bool GetGlyphInfo(int inChar, int &outW, int &outH, int &outAdvance,
                           int &outOx, int &outOy)
   {
      if (!LoadBitmap(inChar,!stroked))
         return false;

      FT_Bitmap *bitmap = &mFace->glyph->bitmap;

      FT_Glyph glyph;
      if (stroked)
      {
         FT_Get_Glyph(mFace->glyph, &glyph);
         FT_Glyph_StrokeBorder(&glyph, stroker, false, false);
         FT_Glyph_To_Bitmap( &glyph, FT_RENDER_MODE_NORMAL, 0, 1 );

         FT_BitmapGlyph glyph_bitmap = (FT_BitmapGlyph)glyph;
         bitmap = &glyph_bitmap->bitmap;
         outOx = glyph_bitmap->left;
         outOy = -glyph_bitmap->top;
      }
      else
      {
         outOx = mFace->glyph->bitmap_left;
         outOy = -mFace->glyph->bitmap_top;
      }


      outW = bitmap->width;
      outH = bitmap->rows;

      if (mTransform & ffUnderline)
      {
         int underlineY0 = mFace->glyph->bitmap_top + getUnderlineOffset() + pad;
         int underlineY1 = underlineY0 + getUnderlineHeight();
         if (outH<underlineY1)
            outH = underlineY1;
      }

      outAdvance = (mFace->glyph->advance.x);

      if (stroked)
         FT_Done_Glyph(glyph);

      return true;
   }


   void RenderGlyph(int inChar,const RenderTarget &outTarget)
   {
      if (!LoadBitmap(inChar,!stroked))
         return;

      int underlineY0 = -1;
      int underlineY1 = -1;

      FT_Bitmap *bitmap = &mFace->glyph->bitmap;
      int ow = bitmap->width;
      int oh = bitmap->rows;

      FT_Glyph glyph;
      if (stroked)
      {
         FT_Get_Glyph(mFace->glyph, &glyph);
         FT_Glyph_StrokeBorder(&glyph, stroker, false, false);
         FT_Glyph_To_Bitmap( &glyph, FT_RENDER_MODE_NORMAL, 0, 1 );

         FT_BitmapGlyph glyph_bitmap = (FT_BitmapGlyph)glyph;
         bitmap = &glyph_bitmap->bitmap;
      }

      int w = bitmap->width;
      int h = bitmap->rows;
 
      if (mTransform & ffUnderline)
      {
         underlineY0 = mFace->glyph->bitmap_top + getUnderlineOffset();
         underlineY1 = underlineY0 + getUnderlineHeight();
      }

      if (h<underlineY1)
         h = underlineY1;

      if (w>outTarget.mRect.w || h>outTarget.mRect.h)
      {
         printf(" too big %d %d\n", outTarget.mRect.w, outTarget.mRect.h);
         return;
      }

      for(int r=0;r<h;r++)
      {
         uint8  *dest = (uint8 *)outTarget.Row(r + outTarget.mRect.y) + outTarget.mRect.x;

         int underline = (r>=underlineY0 && r<underlineY1) ? 0xff : 0;

         if (r<bitmap->rows)
         {
            unsigned char *row = bitmap->buffer + r*bitmap->pitch;
            if (bitmap->pixel_mode == FT_PIXEL_MODE_MONO)
            {
               unsigned int bit = 0;
               unsigned int data = 0;
               for(int x=0;x<outTarget.mRect.w;x++)
               {
                  if (!bit)
                  {
                     bit = 128;
                     data = *row++;
                  }
                  *dest++ =  (underline || (data & bit)) ? 0xff: 0x00;
                  bit >>= 1;
               }
            }
            else if (bitmap->pixel_mode == FT_PIXEL_MODE_GRAY)
            {
               /*
               char buf[1000];
               for(int x=0;x<w;x++)
                  buf[x] = row[x]>128 ? '#' : ' ';
               buf[w] = '\0';
               printf("> %s\n", buf);
               */

               for(int x=0;x<w;x++)
                  *dest ++ = *row++;// | underline;
            }
         }
         else if (r>=underlineY0 && r<underlineY1)
         {
            memset( dest, 0xff, bitmap->pixel_mode == FT_PIXEL_MODE_MONO ? w/8 : w);
         }
         else
         {
            memset( dest, 0x00, bitmap->pixel_mode == FT_PIXEL_MODE_MONO ? w/8 : w);
         }
      }

      if (stroked)
         FT_Done_Glyph(glyph);
   }


   int Height()
   {
      return mFace->size->metrics.height/(1<<6);
   }


   void UpdateMetrics(TextLineMetrics &ioMetrics)
   {
      if (mFace)
      {
         FT_Size_Metrics &metrics = mFace->size->metrics;
         ioMetrics.ascent = std::max( ioMetrics.ascent, (float)metrics.ascender/(1<<6) );
         ioMetrics.descent = std::max( ioMetrics.descent, (float)fabs((float)metrics.descender/(1<<6)) );
         ioMetrics.height = std::max( ioMetrics.height, (float)metrics.height/(1<<6) );
      }
   }

   
};



extern void nmeRegisterFont(const std::string &inName, FontBuffer inData);

extern FontBuffer nmeGetRegisteredFont(const std::string &inName);


#if defined(HX_WINRT) && defined(__cplusplus_winrt)
ByteArray getWinrtDeviceFont(const std::string &inFace);
#endif

int MyNewFace(const std::string &inFace, int inIndex, FT_Face *outFace, FontBuffer inBuffer, void** outBuffer)
{
   *outFace = 0;
   *outBuffer = 0;
   int result = 0;
   result = FT_New_Face(sgLibrary, inFace.c_str(), inIndex, outFace);
   if (*outFace==0)
   {
      #ifdef HXCPP_JS_PRIME
      if (inBuffer)
      {
         result = FT_New_Memory_Face(sgLibrary, inBuffer->getData(), inBuffer->getDataSize(),
                                     inIndex, outFace);
      }
      else
      {
         FILE *file = OpenRead(inFace.c_str());
         if (file)
         {
            fseek(file,0,SEEK_END);
            int len = ftell(file);
            std::vector<unsigned char> data;
            if (len)
            {
               fseek(file,0,SEEK_SET);
               data.resize(len);
               fread(&data[0],len,1,file);
            }
            fclose(file);

            if (len)
            {
               FontBuffer buffer = new BufferData();
               buffer->IncRef();
               buffer->swapData(data);
               result = FT_New_Memory_Face(sgLibrary, buffer->getData(), len, inIndex, outFace);
               nmeRegisterFont(inFace,buffer);
            }
         }
      }
      #else
      ByteArray bytes;
      if (inBuffer == 0)
      {
         bytes = ByteArray::FromFile(inFace.c_str());
         #if defined(HX_WINRT) && defined(__cplusplus_winrt)
         if (!bytes.Ok())
         {
            bytes = getWinrtDeviceFont(inFace);
         }
         #endif
      }
      else
      {
         bytes = ByteArray(inBuffer->get());
      }
      if (bytes.Ok())
      {
         int l = bytes.Size();
         unsigned char *buf = (unsigned char*)malloc(l);
         memcpy(buf,bytes.Bytes(),l);
         result = FT_New_Memory_Face(sgLibrary, buf, l, inIndex, outFace);

         // The font owns the bytes here - so we just leak (fonts are not actually cleaned)
         if (!*outFace)
            free(buf);
         else
            *outBuffer = buf;
      }
      #endif
   }
   //printf("MyNewFace done\n");
   return result;
}





static FT_Face OpenFont(const std::string &inFace, unsigned int inFlags, FontBuffer inBuffer, void** outBuffer)
{
   *outBuffer = 0;
   FT_Face face = 0;
   void* pBuffer = 0;
   // printf("MyNewFace %s with bytes %p\n", inFace.c_str(), inBytes);

   MyNewFace(inFace.c_str(), 0, &face, inBuffer, &pBuffer);
   if (face && inFlags!=0 && face->num_faces>1)
   {
      int n = face->num_faces;
      // Look for other font that may match
      for(int f=1;f<n;f++)
      {
         FT_Face test = 0;
         void* pTestBuffer = 0;
         MyNewFace(inFace.c_str(), f, &test, NULL, &pTestBuffer);
         if (test && test->style_flags == inFlags)
         {
            // A goodie!
            FT_Done_Face(face);
            if (pBuffer) free(pBuffer);
            *outBuffer = pTestBuffer;
            return test;
         }
         else if (test)
            FT_Done_Face(test);
      }
      // The original face will have to do...
   }
   *outBuffer = pBuffer;
   return face;
}





#if defined(HX_WINDOWS) && !defined(HX_WINRT)

#define strcasecmp stricmp

bool GetFontFile(const std::string& inName,std::string &outFile)
{
   
   std::string name = inName;
   
   if (!strcasecmp(inName.c_str(),"_serif"))
   {
      name = "georgia.ttf";
   }
   else if (!strcasecmp(inName.c_str(),"_sans"))
   {
      name = "arial.ttf";
   }
   else if (!strcasecmp(inName.c_str(),"_typewriter"))
   {
      name = "cour.ttf";
   }
   
   // TODO - wchar version
   _TCHAR win_path[2 * MAX_PATH];
   GetWindowsDirectory(win_path, 2*MAX_PATH);
   outFile = std::string(win_path) + "\\Fonts\\" + name;
   FILE *file = fopen(outFile.c_str(),"rb");
   if (file)
   {
      fclose(file);
      return true;
   }

   outFile += ".ttf";
   file = fopen(outFile.c_str(),"rb");
   if (file)
   {
      fclose(file);
      return true;
   }

   return false;
}


#elif defined(GPH)

bool GetFontFile(const std::string& inName,std::string &outFile)
{
   outFile = "/usr/gp2x/HYUni_GPH_B.ttf";
   return true;
}

#elif defined(__APPLE__)
bool GetFontFile(const std::string& inName,std::string &outFile)
{
#ifdef IPHONEOS
//#define FONT_BASE "/System/Library/Fonts/Cache/" before ios8.2
const char *fontFolders[] = { "/System/Library/Fonts/CoreAddition/", "/System/Library/Fonts/Core/", "/System/Library/Fonts/CoreUI/",
			      "/System/Library/Fonts/AppFonts/", "/System/Library/Fonts/LanguageSupport/", "/System/Library/Fonts/Watch/",
			      "/System/Library/Fonts/Extra/", "/System/Library/Fonts/Cache/", 0 };
#else
//#define FONT_BASE "/Library/Fonts/"
const char *fontFolders[] = { "/Library/Fonts/", 0 };
#endif

   const char **testFolder = fontFolders;
   while(*testFolder)
   {
    std::string base = std::string(*testFolder) + inName;
    outFile = base + inName;
    FILE *file = fopen(outFile.c_str(),"rb");
    if (file)
    {
      fclose(file);
      return true;
    }

    outFile = base + ".ttf";
    file = fopen(outFile.c_str(),"rb");
    if (file)
    {
      fclose(file);
      return true;
    }


    #ifdef HX_MACOS
    outFile = base + ".otf";
    file = fopen(outFile.c_str(),"rb");
    if (file)
    {
      fclose(file);
      return true;
    }

    outFile = base + ".ttc";
    file = fopen(outFile.c_str(),"rb");
    if (file)
    {
      fclose(file);
      return true;
    }
    #endif


    const char *serifFonts[] = { "Georgia.ttf", "Times.ttf", "Times New Roman.ttf", 0 };
    const char *sansFonts[] = { "Arial.ttf", "Helvetica.ttf", "Arial Black.ttf", 0 };
    const char *fixedFonts[] = { "Courier New.ttf", "CourierNew.ttf", "Courier.ttf", 0 };

    const char **test = 0;

    if (!strcasecmp(inName.c_str(),"_serif") || !strcasecmp(inName.c_str(),"times.ttf") || !strcasecmp(inName.c_str(),"times"))
      test = serifFonts;
    else if (!strcasecmp(inName.c_str(),"_sans") || !strcasecmp(inName.c_str(),"helvetica.ttf"))
      test = sansFonts;
    else if (!strcasecmp(inName.c_str(),"_typewriter") || !strcasecmp(inName.c_str(),"courier.ttf"))
      test = fixedFonts;
    else if (!strcasecmp(inName.c_str(),"arial.ttf"))
      test = sansFonts;

    if (test)
    {
      while(*test)
      {
         outFile = std::string(*testFolder) + std::string(*test);

         //printf("Try %s\n", outFile.c_str());

	     FILE *file = fopen(outFile.c_str(),"rb");
	     if (file)
	     {
	        //printf("Found sub file %s\n", outFile.c_str());
	        fclose(file);
	        return true;
	     }
         test++;
      }
    }

    testFolder++;
   }

   return false;
}
#else

#if defined(HX_WINRT)
#define strcasecmp stricmp
#endif

bool GetFontFile(const std::string& inName,std::string &outFile)
{
   const char *alternate = 0;
   if (!strcasecmp(inName.c_str(),"_serif") ||
       !strcasecmp(inName.c_str(),"times.ttf") || !strcasecmp(inName.c_str(),"times"))
   {
      
      #if defined (ANDROID)
         outFile = "/system/fonts/DroidSerif-Regular.ttf";
         alternate = "/system/fonts/NotoSerif-Regular.ttf";
      #elif defined (WEBOS)
         outFile = "/usr/share/fonts/times.ttf";
      #elif defined (BLACKBERRY)
         outFile = "/usr/fonts/font_repository/monotype/times.ttf";
      #elif defined (TIZEN)
         outFile = "/usr/share/fonts/TizenSansRegular.ttf";
      #elif defined(HX_WINRT) && defined(__cplusplus_winrt)
         outFile = "Georgia";
      #else
         outFile = "/usr/share/fonts/truetype/freefont/FreeSerif.ttf";
      #endif
      
   }
   else if (!strcasecmp(inName.c_str(),"_sans") || !strcasecmp(inName.c_str(),"arial.ttf") ||
              !strcasecmp(inName.c_str(),"arial") || !strcasecmp(inName.c_str(),"sans-serif") )
   {
      
      #if defined (ANDROID)
         outFile = "/system/fonts/DroidSans.ttf";
      #elif defined (WEBOS)
         outFile = "/usr/share/fonts/Prelude-Medium.ttf";
      #elif defined (BLACKBERRY)
         outFile = "/usr/fonts/font_repository/monotype/arial.ttf";
      #elif defined (TIZEN)
         outFile = "/usr/share/fonts/TizenSansRegular.ttf";
      #elif defined(HX_WINRT) && defined(__cplusplus_winrt)
         outFile = "Arial";
      #else
         outFile = "/usr/share/fonts/truetype/freefont/FreeSans.ttf";
      #endif
      
   }
   else if (!strcasecmp(inName.c_str(),"_typewriter") || !strcasecmp(inName.c_str(),"courier.ttf") || !strcasecmp(inName.c_str(),"courier"))
   {
      #if defined (ANDROID)
         outFile = "/system/fonts/DroidSansMono.ttf";
      #elif defined (WEBOS)
         outFile = "/usr/share/fonts/cour.ttf";
      #elif defined (BLACKBERRY)
         outFile = "/usr/fonts/font_repository/monotype/cour.ttf";
      #elif defined (TIZEN)
         outFile = "/usr/share/fonts/TizenSansRegular.ttf";
      #elif defined(HX_WINRT) && defined(__cplusplus_winrt)
         outFile = "Courier New";
      #else
         outFile = "/usr/share/fonts/truetype/freefont/FreeMono.ttf";
      #endif
      
   }
   else
   {
      #ifdef ANDROID
      //__android_log_print(ANDROID_LOG_INFO, "GetFontFile", "Could not load font %s.", inName.c_str() );
      #endif
      
      //printf("Unfound font: %s\n",inName.c_str());
      return false;
   }

   #ifdef ANDROID
   if (alternate)
   {
       struct stat s;
       if (stat(outFile.c_str(),&s)!=0 && stat(alternate,&s)==0)
          outFile = alternate;
   }

    //__android_log_print(ANDROID_LOG_INFO, "GetFontFile", "mapped '%s' to '%s'.", inName.c_str(), outFile.c_str());
   #endif
   return true;
}
#endif


std::string ToAssetName(const std::string &inPath)
{
#if HX_MACOS
   std::string flat;
   for(int i=0;i<inPath.size();i++)
   {
      int ch = inPath[i];
      if ( (ch>='a' && ch<='z') || (ch>='0' && ch<='9') )
         { }
      else if (ch>='A' && ch<='Z')
         ch += 'a' - 'A';
      else
         ch = '_';

      flat.push_back(ch);
   }

   char name[1024];
   GetBundleFilename(flat.c_str(),name,1024);
   return name;
#else
   return gAssetBase + "/" + inPath;
#endif
}

FT_Face FindFont(const std::string &inFontName, unsigned int inFlags, FontBuffer inBuffer, void** pBuffer)
{
   std::string fname = inFontName;
   
   /*
   #ifndef ANDROID
   if (fname.find(".") == std::string::npos && fname.find("_") == std::string::npos)
      fname += ".ttf";
   #endif
   */
     
   FT_Face font = OpenFont(fname,inFlags,inBuffer, pBuffer);

   if (font==0 && fname.find("\\")==std::string::npos && fname.find("/")==std::string::npos)
   {
      std::string file_name;

      #if HX_MACOS
      font = OpenFont(ToAssetName(fname).c_str(),inFlags,NULL,pBuffer);
      if (!font)
         font = OpenFont(ToAssetName(fname+".ttf").c_str(),inFlags,NULL,pBuffer);
      #endif

      if (font==0 && GetFontFile(fname,file_name))
      {
         font = OpenFont(file_name.c_str(),inFlags,NULL,pBuffer);
      }
   }


   return font;
}


extern const char *RemapFontName(const char *inName);

FontFace *FontFace::CreateFreeType(const TextFormat &inFormat,double inScale,FontBuffer inBytes, const std::string &inCombinedName)
{
   if (!sgLibrary)
     FT_Init_FreeType( &sgLibrary );
   if (!sgLibrary)
      return 0;

   FT_Face face = 0;
   std::string str = inCombinedName=="" ? WideToUTF8(inFormat.font) : inCombinedName;

   uint32 flags = 0;
   if (inCombinedName=="")
   {
      if (inFormat.bold)
         flags |= ffBold;
      if (inFormat.italic)
         flags |= ffItalic;
   }

   int scaledOutline = 0;
   int miter8d8 = 0;
   if (inFormat.outline.Get()>0 )
   {
      scaledOutline = (int )(inFormat.outline*inScale*64 + 0.5);
      if (scaledOutline>16)
      {
         miter8d8 = inFormat.outlineMiterLimit*256;
         if (miter8d8>0xffff) miter8d8 = 0xffff;
         flags |= inFormat.outlineFlags.Get() | ((scaledOutline>>4)<<8);
         flags ^= (miter8d8<<16);
      }
      else
         scaledOutline = 0;
   }

   
   void* pBuffer = 0;
   face = FindFont(str,flags,inBytes,&pBuffer);
   if (!face)
   {
      const char *alternate = RemapFontName(str.c_str());
      if (alternate)
         face = FindFont(alternate,flags,inBytes,&pBuffer);
   }

   if (!face)
      return 0;

   int height = (int )(inFormat.size*inScale + 0.5);
   FT_Set_Pixel_Sizes(face,0, height);

   uint32 transform = 0;
   if (inCombinedName=="")
   {
      if ( !(face->style_flags & ffBold) && inFormat.bold )
         transform |= ffBold;
      if ( !(face->style_flags & ffItalic) && inFormat.italic )
         transform |= ffItalic;
   }
   if ( inFormat.underline )
      transform |= ffUnderline;

   return new FreeTypeFont(face,height,scaledOutline,inFormat.outlineFlags.Get(),miter8d8<<8,transform,pBuffer);
}





} // end namespace nme

#include <nme/NmeCffi.h>

// Font outlines as data - from the SamHaXe project

#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OUTLINE_H

namespace {
enum {
   PT_MOVE = 1,
   PT_LINE = 2,
   PT_CURVE = 3
};

struct point {
   int            x, y;
   unsigned char  type;

   point() { }
   point(int x, int y, unsigned char type) : x(x), y(y), type(type) { }
};

struct glyph {
   FT_ULong                char_code;
   FT_Vector               advance;
   FT_Glyph_Metrics        metrics;
   int                     index, x, y;
   std::vector<int>        pts;

   glyph(): x(0), y(0) { }
};

struct kerning {
   int                     l_glyph, r_glyph;
   int                     x, y;

   kerning() { }
   kerning(int l, int r, int x, int y): l_glyph(l), r_glyph(r), x(x), y(y) { }
};

struct glyph_sort_predicate {
   bool operator()(const glyph* g1, const glyph* g2) const {
      return g1->char_code <  g2->char_code;
   }
};

#ifdef GPH
typedef FT_Vector *FVecPtr;
#else
typedef const FT_Vector *FVecPtr;
#endif

int outline_move_to(FVecPtr to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_MOVE);
   g->pts.push_back(to->x);
   g->pts.push_back(to->y);

   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_line_to(FVecPtr to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_LINE);
   g->pts.push_back(to->x - g->x);
   g->pts.push_back(to->y - g->y);
   
   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_conic_to(FVecPtr ctl, FVecPtr to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_CURVE);
   g->pts.push_back(ctl->x - g->x);
   g->pts.push_back(ctl->y - g->y);
   g->pts.push_back(to->x - ctl->x);
   g->pts.push_back(to->y - ctl->y);
   
   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_cubic_to(FVecPtr, FVecPtr , FVecPtr , void *user) {
   // Cubic curves are not supported
   return 1;
}

value get_familyname_from_sfnt_name(FT_Face face)
{
   wchar_t *family_name = NULL;
   FT_SfntName sfnt_name;
   FT_UInt num_sfnt_names, sfnt_name_index;
   int len, i;
   
   if (FT_IS_SFNT(face))
   {
      num_sfnt_names = FT_Get_Sfnt_Name_Count(face);
      sfnt_name_index = 0;
      while (sfnt_name_index < num_sfnt_names)
      {
         if (!FT_Get_Sfnt_Name(face, sfnt_name_index++, (FT_SfntName *)&sfnt_name) && sfnt_name.name_id == TT_NAME_ID_FULL_NAME)
         {
            if (sfnt_name.platform_id == TT_PLATFORM_MACINTOSH)
            {
               len = sfnt_name.string_len;
               return alloc_string_len((const char *)sfnt_name.string, sfnt_name.string_len);
            }
            else if ((sfnt_name.platform_id == TT_PLATFORM_MICROSOFT) && (sfnt_name.encoding_id == TT_MS_ID_UNICODE_CS))
            {
               /* Note that most fonts contains a Unicode charmap using
                  TT_PLATFORM_MICROSOFT, TT_MS_ID_UNICODE_CS.
               */
               
               /* .string :
                     Note that its format differs depending on the 
                     (platform,encoding) pair. It can be a Pascal String, 
                     a UTF-16 one, etc..
                     Generally speaking, the string is "not" zero-terminated.
                     Please refer to the TrueType specification for details..
                      
                  .string_len :
                     The length of `string' in bytes.
               */
               
               len = sfnt_name.string_len / 2;
               family_name = (wchar_t*)malloc((len + 1) * sizeof(wchar_t));
               for(i = 0; i < len; i++)
               {
                  family_name[i] = ((wchar_t)sfnt_name.string[i*2 + 1]) | (((wchar_t)sfnt_name.string[i*2]) << 8);
               }
               family_name[len] = L'\0';
               value result = alloc_wstring(family_name);
               free(family_name);
               return result;
            }
         }
      }
   }
   
   return val_null;
}

} // end namespace

value freetype_init()
{
   if (!nme::sgLibrary)
     FT_Init_FreeType( &nme::sgLibrary );

   return alloc_bool(nme::sgLibrary);
}
DEFINE_PRIM(freetype_init, 0);



namespace nme {
std::string GetFreeTypeFaceName(FontBuffer inBytes)
{
   if (!nme::sgLibrary)
     FT_Init_FreeType( &nme::sgLibrary );

   FT_Face face =0;
   #ifdef HXCPP_JS_PRIME
   int result = FT_New_Memory_Face(sgLibrary, inBytes->getData(), inBytes->getDataSize(),0,&face);
   #else
   ByteArray bytes(inBytes->get());
   if (!bytes.Ok())
      return "";
   int result = FT_New_Memory_Face(sgLibrary, bytes.Bytes(), bytes.Size(), 0, &face);
   #endif
   if (result != 0 || !face)
      return "";

   value family_name = get_familyname_from_sfnt_name(face);
   FT_Done_Face(face);

   return valToStdString(family_name);
}
}





value freetype_import_font(value font_file, value char_vector, value em_size, value inBytes)
{
   freetype_init();

   FT_Face           face;
   int               result, i, j;

   val_check(font_file, string);
   val_check(em_size, int);
   
   void* pBuffer = 0;
   std::string faceName = valToStdString(font_file);
   nme::FontBuffer fontBuffer = nme::nmeGetRegisteredFont(faceName);
   nme::FontBuffer bytes = 0;

   if (fontBuffer)
   {
      result = nme::MyNewFace(faceName, 0, &face, fontBuffer, &pBuffer);
   }
   else
   {
      #ifndef HXCPP_JS_PRIME
      bytes = !val_is_null(inBytes) ? new AutoGCRoot(inBytes) : NULL;
      result = nme::MyNewFace(faceName, 0, &face, bytes, &pBuffer);
      #else
      bytes = val_is_null(inBytes) ? 0 : nme::val_to_buffer(inBytes);
      if (bytes)
         bytes->IncRef();
      result = nme::MyNewFace(faceName, 0, &face, bytes, &pBuffer);
      #endif
   }

   if (result == FT_Err_Unknown_File_Format)
   {
      val_throw(alloc_string("Unknown file format!"));
      return alloc_null();
   }
   else if (result != 0)
   {
      val_throw(alloc_string("File open error!"));
      return alloc_null();
   }

   if (!FT_IS_SCALABLE(face))
   {
      FT_Done_Face(face);
      if (pBuffer) free(pBuffer);
      
      val_throw(alloc_string("Font is not scalable!"));
      return alloc_null();
   }

   value  family_name = get_familyname_from_sfnt_name(face);

   value  ret = alloc_empty_object();

   alloc_field(ret, val_id("has_kerning"), alloc_bool(FT_HAS_KERNING(face)));
   alloc_field(ret, val_id("is_fixed_width"), alloc_bool(FT_IS_FIXED_WIDTH(face)));
   alloc_field(ret, val_id("has_glyph_names"), alloc_bool(FT_HAS_GLYPH_NAMES(face)));
   alloc_field(ret, val_id("is_italic"), alloc_bool(face->style_flags & FT_STYLE_FLAG_ITALIC));
   alloc_field(ret, val_id("is_bold"), alloc_bool(face->style_flags & FT_STYLE_FLAG_BOLD));
   alloc_field(ret, val_id("family_name"), val_is_null(family_name) ? alloc_string(face->family_name) : family_name);
   alloc_field(ret, val_id("style_name"), alloc_string(face->style_name));
   alloc_field(ret, val_id("em_size"), alloc_int(face->units_per_EM));
   alloc_field(ret, val_id("ascend"), alloc_int(face->ascender));
   alloc_field(ret, val_id("descend"), alloc_int(face->descender));
   alloc_field(ret, val_id("height"), alloc_int(face->height));


   // We are loading unscaled, so you must use the returned em_size
   // Use this flag to tell if we actually want the details...
   bool wantOutlines = val_int(em_size)>0;

   if (wantOutlines)
   {
      std::vector<glyph*> glyphs;

      FT_Outline_Funcs ofn =
      {
         outline_move_to,
         outline_line_to,
         outline_conic_to,
         outline_cubic_to,
         0, // shift
         0  // delta
      };


      if (!val_is_null(char_vector))
      {
         // Import only specified characters
         int  num_char_codes = val_array_size(char_vector);

         for(i=0; i<num_char_codes; i++)
         {
            FT_ULong    char_code = (FT_ULong)val_int(val_array_i(char_vector,i));
            FT_UInt     glyph_index = FT_Get_Char_Index(face, char_code);

            if(glyph_index != 0 && FT_Load_Glyph(face, glyph_index, FT_LOAD_NO_BITMAP|FT_LOAD_NO_HINTING|FT_LOAD_NO_SCALE) == 0)
            {
               glyph *g = new glyph;

               result = FT_Outline_Decompose(&face->glyph->outline, &ofn, g);
               if(result == 0)
               {
                  g->index = glyph_index;
                  g->char_code = char_code;
                  g->metrics = face->glyph->metrics;
                  glyphs.push_back(g);
               }
               else
                  delete g;
            }
         }

      }
      else
      {
         // Import every character in face
         FT_ULong    char_code;
         FT_UInt     glyph_index;

         char_code = FT_Get_First_Char(face, &glyph_index);
         while(glyph_index != 0)
         {
            // Just need outline - no hinting or bitmap
            if(FT_Load_Glyph(face, glyph_index,FT_LOAD_NO_BITMAP|FT_LOAD_NO_HINTING|FT_LOAD_NO_SCALE) == 0)
            {
               glyph *g = new glyph;

               result = FT_Outline_Decompose(&face->glyph->outline, &ofn, g);
               if(result == 0)
               {
                  g->index = glyph_index;
                  g->char_code = char_code;
                  g->metrics = face->glyph->metrics;
                  glyphs.push_back(g);
               }
               else
                  delete g;
            }
            
            char_code = FT_Get_Next_Char(face, char_code, &glyph_index);  
         }
      }

      // Ascending sort by character codes
      std::sort(glyphs.begin(), glyphs.end(), glyph_sort_predicate());

      std::vector<kerning>  kern;
      if (FT_HAS_KERNING(face))
      {
         int         n = glyphs.size();
         FT_Vector   v;

         for(i = 0; i < n; i++)
         {
            int  l_glyph = glyphs[i]->index;

            for(j = 0; j < n; j++)
            {
               int   r_glyph = glyphs[j]->index;

               FT_Get_Kerning(face, l_glyph, r_glyph, FT_KERNING_UNSCALED, &v);
               if(v.x != 0 || v.y != 0)
                  kern.push_back( kerning(i, j, v.x, v.y) );
            }
         }
      }

      int           num_glyphs = glyphs.size();
      alloc_field(ret, val_id("num_glyphs"), alloc_int(num_glyphs));


      // 'glyphs' field
      value             neko_glyphs = alloc_array(num_glyphs);
      for(i=0; i < glyphs.size(); i++)
      {
         glyph          *g = glyphs[i];
         int            num_points = g->pts.size();

         value          points = alloc_array(num_points);
         
         for(j = 0; j < num_points; j++)
            val_array_set_i(points,j,alloc_int(g->pts[j]));

         value item = alloc_empty_object();
         val_array_set_i(neko_glyphs,i,item);
         alloc_field(item, val_id("char_code"), alloc_int(g->char_code));
         alloc_field(item, val_id("advance"), alloc_int(g->metrics.horiAdvance));
         alloc_field(item, val_id("min_x"), alloc_int(g->metrics.horiBearingX));
         alloc_field(item, val_id("max_x"), alloc_int(g->metrics.horiBearingX + g->metrics.width));
         alloc_field(item, val_id("min_y"), alloc_int(g->metrics.horiBearingY - g->metrics.height));
         alloc_field(item, val_id("max_y"), alloc_int(g->metrics.horiBearingY));
         alloc_field(item, val_id("points"), points);

         delete g;
      }
      alloc_field(ret, val_id("glyphs"), neko_glyphs);

      // 'kerning' field
      if (FT_HAS_KERNING(face))
      {
         value       neko_kerning = alloc_array(kern.size());

         for(i = 0; i < kern.size(); i++)
         {
            kerning  *k = &kern[i];

            value item = alloc_empty_object();
            val_array_set_i(neko_kerning,i,item);
            alloc_field(item, val_id("left_glyph"), alloc_int(k->l_glyph));
            alloc_field(item, val_id("right_glyph"), alloc_int(k->r_glyph));
            alloc_field(item, val_id("x"), alloc_int(k->x));
            alloc_field(item, val_id("y"), alloc_int(k->y));
         }

         alloc_field(ret, val_id("kerning"), neko_kerning);
      }
      else
         alloc_field(ret, val_id("kerning"), alloc_null());
   }

   FT_Done_Face(face);

   #ifdef HXCPP_JS_PRIME
   if (bytes)
      bytes->DecRef();
   #else
   delete bytes;
   #endif
   if (pBuffer)
   {
      free(pBuffer);
   }

   return ret;
}

DEFINE_PRIM(freetype_import_font, 4);


bool ChompEnding(std::string &ioName, const std::string &inEnding)
{
   int leadIn =  ioName.size() - inEnding.size();
   if (leadIn>0 && ioName.substr(leadIn)==inEnding)
   {
      ioName = ioName.substr(0,leadIn);
      return true;
   }
   return false;
}

void SendFont(std::string name, value inFunc)
{
   enum FontStyle
   {
      BOLD,
      BOLD_ITALIC,
      ITALIC,
      REGULAR,
   };
   #ifndef HX_WINRT
   size_t pos = name.find_last_of('.');
   if (pos!=std::string::npos)
      name = name.substr(0,pos);
   #endif

   FontStyle style = REGULAR; 
   if (ChompEnding(name," Bold Italic"))
      style = BOLD_ITALIC;
   else if (ChompEnding(name," Italic"))
      style = ITALIC;
   else if (ChompEnding(name," Bold"))
      style = BOLD;
      
   val_call2(inFunc,alloc_string_len(name.c_str(),name.size()), alloc_int(style) );
}

#if defined(HX_WINRT)
void winrtItererateDeviceFonts(value inFunc);
#else
void ItererateFontDir(const std::string &inDir, value inFunc, int inMaxDepth)
{
   #if defined(HX_WINDOWS)
   std::string search = inDir + "*.ttf";

   WIN32_FIND_DATA d;
   HANDLE handle = FindFirstFile(search.c_str(),&d);
   if( handle == INVALID_HANDLE_VALUE )
   {
      return;
   }
   while( true )
   {
      // skip magic dirs
      //if( d.cFileName[0] != '.' || (d.cFileName[1] != 0 && (d.cFileName[1] != '.' || d.cFileName[2] != 0)) )
      SendFont(d.cFileName,inFunc);

      if( !FindNextFile(handle,&d) )
         break;
   }
   #elif !defined(EPPC)
   DIR *d = opendir(inDir.c_str());
   if (d)
   {
      while( true )
      {
         struct dirent *e = readdir(d);
         if (!e)
           break;
         // skip magic dirs
         if( e->d_name[0] == '.' && (e->d_name[1] == 0 || (e->d_name[1] == '.' && e->d_name[2] == 0)) )
            continue;
         std::string full = inDir + e->d_name + "/";

         struct stat s;
         if ( inMaxDepth>0 && stat(full.c_str(),&s)==0 && (s.st_mode & S_IFDIR) )
         {
            // TODO - record sub directory for later?
            ItererateFontDir(full, inFunc, inMaxDepth-1);
         }
         else
         {
            const char *dot = e->d_name;
            while(*dot && *dot!='.') dot++;
            if (dot && !strcmp(dot+1,"ttf"))
              SendFont(e->d_name,inFunc);
         }
      }
      closedir(d);
   }
   #endif
}
#endif

void nme_font_iterate_device_fonts(value inFunc)
{
   #ifdef HX_WINRT
      winrtItererateDeviceFonts(inFunc);
   #else
      #ifdef HX_WINDOWS
      char win_path[2 * MAX_PATH];
      GetWindowsDirectory(win_path, 2*MAX_PATH);
      strcat(win_path,"\\Fonts\\");
      #endif
   
   
      //std::string fontDir =
      const char *fontFolders[] = {
         #if defined (ANDROID)
            "/system/fonts/"
         #elif defined (WEBOS)
            "/usr/share/fonts/"
         #elif defined (BLACKBERRY)
            "/usr/fonts/font_repository/"
         #elif defined(IPHONEOS)
            "/System/Library/Fonts/CoreAddition/", "/System/Library/Fonts/Core/", "/System/Library/Fonts/CoreUI/",
	    "/System/Library/Fonts/AppFonts/", "/System/Library/Fonts/LanguageSupport/", "/System/Library/Fonts/Watch/",
	    "/System/Library/Fonts/Extra/", "/System/Library/Fonts/Cache/"
         #elif defined(__APPLE__)
            "/Library/Fonts/"
         #elif defined(HX_WINDOWS)
           win_path
         #else
            "/usr/share/fonts/truetype/"
         #endif
      , 0};

      const char **testFolder = fontFolders;
      while(*testFolder)
      {
         std::string fontDir = std::string(*testFolder);
         ItererateFontDir(fontDir, inFunc, 1);
         testFolder++;
      }
   #endif
}
DEFINE_PRIME1v(nme_font_iterate_device_fonts)


#if defined(HX_WINRT) && defined(__cplusplus_winrt)
namespace nme
{
   ByteArray getWinrtDeviceFont(const std::string &inFace)
   {
      IDWriteFactory *writeFactory;
      if(SUCCEEDED(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), reinterpret_cast<IUnknown**>(&writeFactory))))
      {
         IDWriteFontCollection *fontCollection;
         if(SUCCEEDED(writeFactory->GetSystemFontCollection(&fontCollection, TRUE)))
         {
            UINT32 index;
            BOOL exists;
            std::wstring fontNameW;
            fontNameW.assign(inFace.begin(), inFace.end());
            if(SUCCEEDED(fontCollection->FindFamilyName(fontNameW.c_str(), &index, &exists)))
            {
               if(exists)
               {
                  IDWriteFontFamily *fontFamily;
                  if(SUCCEEDED(fontCollection->GetFontFamily(index, &fontFamily)))
                  {
                     IDWriteFont *matchingFont;
                     if(SUCCEEDED(fontFamily->GetFirstMatchingFont(DWRITE_FONT_WEIGHT_REGULAR, DWRITE_FONT_STRETCH_NORMAL, DWRITE_FONT_STYLE_NORMAL, &matchingFont)))
                     {
                        IDWriteFontFace *fontFace;
                        if(SUCCEEDED(matchingFont->CreateFontFace(&fontFace)))
                        {
                           IDWriteFontFile *fontFile;
                           UINT32 numberOfFiles = 1;
                           if(SUCCEEDED(fontFace->GetFiles(&numberOfFiles, &fontFile)))
                           {
                              const void *fontFileReferenceKey;
                              UINT32 fontFileReferenceKeySize;
                              if(SUCCEEDED(fontFile->GetReferenceKey(&fontFileReferenceKey, &fontFileReferenceKeySize)))
                              {
                                 IDWriteFontFileLoader *fontFileLoader;
                                 if(SUCCEEDED(fontFile->GetLoader(&fontFileLoader)))
                                 {
                                    IDWriteFontFileStream *fontFileStream;
                                    if(SUCCEEDED(fontFileLoader->CreateStreamFromKey(fontFileReferenceKey, fontFileReferenceKeySize, &fontFileStream)))
                                    {
                                       UINT64 fileSize;
                                       if(SUCCEEDED(fontFileStream->GetFileSize(&fileSize)))
                                       {
                                          const void *fragmentStart;
                                          void *fragmentContext;
                                          if(SUCCEEDED(fontFileStream->ReadFileFragment(&fragmentStart, 0, fileSize, &fragmentContext)))
                                          {
                                             ByteArray bytes((size_t)fileSize);
                                             memcpy(bytes.Bytes(), fragmentStart, (size_t)fileSize);

                                             fontFileStream->ReleaseFileFragment(fragmentContext);
                                             fontFileStream->Release();
                                             fontFileLoader->Release();
                                             fontFile->Release();
                                             fontFace->Release();
                                             matchingFont->Release();
                                             fontFamily->Release();
                                             fontCollection->Release();
                                             writeFactory->Release();

                                             return bytes;
                                          }
                                       }
                                    }
                                    fontFileStream->Release();
                                 }
                                 fontFileLoader->Release();
                              }
                              fontFile->Release();
                           }
                           fontFace->Release();
                        }
                        matchingFont->Release();
                     }
                     fontFamily->Release();
                  }
               }
            }
            fontCollection->Release();
         }
         writeFactory->Release();
      }
      return ByteArray();
   }
}

//#  define DLOG(fmt, ...) {char buf[1024];sprintf(buf,"****LOG: %s(%d): %s \n    [" fmt "]\n",__FILE__,__LINE__,__FUNCTION__, __VA_ARGS__);OutputDebugString(buf);}

void winrtItererateDeviceFonts(value inFunc)
{
  IDWriteFactory *writeFactory;
  if (SUCCEEDED(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), reinterpret_cast<IUnknown**>(&writeFactory))))
  {
    IDWriteFontCollection *fontCollection;
    if (SUCCEEDED(writeFactory->GetSystemFontCollection(&fontCollection, TRUE)))
    {
      UINT32 familyCount = fontCollection->GetFontFamilyCount();
      if (familyCount>0)
      {
        uint32 index = 0;
        BOOL exists = false;
        wchar_t localeName[LOCALE_NAME_MAX_LENGTH];
        int defaultLocaleSuccess = GetUserDefaultLocaleName(localeName, LOCALE_NAME_MAX_LENGTH);
        for (UINT32 i = 0; i < familyCount; ++i)
        {
          IDWriteFontFamily *fontFamily;
          if (SUCCEEDED(fontCollection->GetFontFamily(i, &fontFamily)))
          {
            IDWriteLocalizedStrings *familyNames;
            if (SUCCEEDED(fontFamily->GetFamilyNames(&familyNames)))
            {
              if (defaultLocaleSuccess)
              {
                if (SUCCEEDED(familyNames->FindLocaleName(localeName, &index, &exists))) 
                {
                  if (!exists)
                  {
                    familyNames->FindLocaleName(L"en-us", &index, &exists);
                  }
                }
              }
              if (!exists)
              {
                index = 0;
              }
              UINT32 length = 0;
              if (SUCCEEDED(familyNames->GetStringLength(index, &length)))
              {
                wchar_t* name = new (std::nothrow) wchar_t[length+1];
                if (name != nullptr && SUCCEEDED(familyNames->GetString(index, name, length+1)))
                {
                  std::wstring ws(name);
                  std::string strName(ws.begin(), ws.end());
                  //DLOG("i: %d, index %d, font: %s", i, index, strName.c_str());
                  SendFont(strName,inFunc);
                }
              }
            }
            fontFamily->Release();
          }
        }
      }
      fontCollection->Release();
    }
    writeFactory->Release();
  }
}

#endif

