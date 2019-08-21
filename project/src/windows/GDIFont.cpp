#include <Font.h>
#include <windows.h>
#include <algorithm>
#ifdef max
#undef max
#undef min
#endif

namespace nme
{

static HDC sgFontDC = 0;
static HBITMAP sgDIB = 0;
static HBITMAP sgOldDIB = 0;
static ARGB *sgDIBBits = 0;
static int sgDIB_W = 0;
static int sgDIB_H = 0;
static unsigned char sGammaLUT[256];
static bool sGammaLUTInit = false;

class GDIFont : public FontFace
{
public:
   bool bold;
   bool italic;

   GDIFont(HFONT inFont, int inHeight, bool inBold, bool inItalic) : mFont(inFont), mPixelHeight(inHeight)
   {
      bold = inBold;
      italic = inItalic;
      SelectObject(sgFontDC,mFont);
      GetTextMetrics(sgFontDC,&mMetrics);
   }

   ~GDIFont()
   {
      DeleteObject(mFont);
   }

   virtual bool GetGlyphInfo(int inChar, int &outW, int &outH, int &outAdvance,
                           int &outOx, int &outOy)
   {
      wchar_t ch = inChar;
      SelectObject(sgFontDC,mFont);
      SIZE size;
      GetTextExtentPointW(sgFontDC,  &ch, 1, &size );
      outW = size.cx;
      if (italic)
         outW += ( (size.cy+7)>>3 );
      outH = size.cy;
      outAdvance = size.cx<<6;
      outOx = 0;
      outOy = -mMetrics.tmAscent;
      return true;
   }

   void RenderGlyph(int inChar, const RenderTarget &outTarget)
   {
      if (!sGammaLUTInit)
      {
         double pow_max = 255.0/pow(255,1.9);
         for(int i=0;i<256;i++)
         {
            sGammaLUT[i] = pow(i,1.9)*pow_max + 0.5;
         }
         sGammaLUTInit = true;
      }
      int w = outTarget.mRect.w;
      w = (w+3) & ~3;
      int h = outTarget.mRect.h;
      if (w>sgDIB_W || h>sgDIB_H)
      {
         if (sgDIB)
         {
            SelectObject(sgFontDC,sgOldDIB);
            DeleteObject(sgDIB);
         }
         BITMAPINFO bmi;
         memset(&bmi,0,sizeof(bmi));
         bmi.bmiHeader.biSize = sizeof(bmi.bmiHeader);
         bmi.bmiHeader.biWidth = w;
         bmi.bmiHeader.biHeight = h;
         bmi.bmiHeader.biPlanes = 1;
         bmi.bmiHeader.biBitCount = 32;
         bmi.bmiHeader.biCompression = BI_RGB;
         sgDIB_W = w;
         sgDIB_H = h;

         sgDIB = CreateDIBSection(sgFontDC,&bmi,DIB_RGB_COLORS, (void **)&sgDIBBits, 0, 0 );
         sgOldDIB = (HBITMAP)SelectObject(sgFontDC,sgDIB);
      }
      memset(sgDIBBits,0,sgDIB_W*sgDIB_H*4);
      wchar_t ch = inChar;
      TextOutW(sgFontDC,0,0,&ch,1);

      for(int y=0;y<outTarget.mRect.h;y++)
      {
         ARGB *src = sgDIBBits + (sgDIB_H - 1 - y)*sgDIB_W;
         uint8  *dest = (uint8 *)outTarget.Row(y + outTarget.mRect.y) + outTarget.mRect.x;
         for(int x=0;x<outTarget.mRect.w;x++)
            *dest++= sGammaLUT[(src++)->g];
      }

   }

   void UpdateMetrics(TextLineMetrics &ioMetrics)
   {
      ioMetrics.ascent = std::max( ioMetrics.ascent, (float)mMetrics.tmAscent);
      ioMetrics.descent = std::max( ioMetrics.descent, (float)mMetrics.tmDescent);
      ioMetrics.height = std::max( ioMetrics.height, (float)mMetrics.tmHeight);
   }

   int Height()
   {
      return mMetrics.tmHeight;
   }

   virtual bool IsNative() { return true; }



   HFONT mFont;
   TEXTMETRIC mMetrics;
   int mPixelHeight;
};

int CALLBACK MyEnumFontFunc(
    const LOGFONTW *lpelfe,
    const TEXTMETRICW *lpntme,
    DWORD FontType,
    LPARAM lParam
)
{
   return 0;
}



FontFace *FontFace::CreateNative(const TextFormat &inFormat,double inScale)
{
   //The height needs to be >=1, 0 causes the font mapper to use the default height
   int height = (int)std::max(( 0.5 + inFormat.size*inScale ), 1.0);
   LOGFONTW desc;
   memset(&desc,0,sizeof(desc));

   desc.lfHeight = -height;
   //desc.lfWidth; 
   //desc.lfEscapement; 
   //desc.lfOrientation; 
   desc.lfWeight = inFormat.bold ? FW_BOLD : FW_NORMAL;
   desc.lfItalic = inFormat.italic;
   desc.lfUnderline = inFormat.underline;
   //desc.lfStrikeOut; 
   desc.lfCharSet = DEFAULT_CHARSET; 
   desc.lfOutPrecision = OUT_RASTER_PRECIS; 
   desc.lfClipPrecision = CLIP_DEFAULT_PRECIS; 
   desc.lfQuality = ANTIALIASED_QUALITY; 
   desc.lfPitchAndFamily = DEFAULT_PITCH | FF_DONTCARE; 
   wcsncpy(desc.lfFaceName,inFormat.font(L"times").c_str(),LF_FACESIZE);


   // Check to see if it is there....
   for(int pass=0;pass<3;pass++)
   {
     // got nothing..
     if (pass==2)
       return 0;

     if (pass==1)
     {
        WString name = inFormat.font(L"times").c_str();
        for(int i=0;i<name.size();i++)
           if (name[i]>='A' && name[i]<='Z')
              name[i] = name[i] - 'A' + 'a';

        if (name==L"serif" ||
            name==L"\"serif\"" ||
            name==L"_serif" ||
            name==L"times.ttf")
           wcsncpy(desc.lfFaceName,L"times",LF_FACESIZE);
        else if (name==L"sans" ||
                 name==L"\"sans\"" ||
                 name==L"_sans" ||
                 name==L"sans-serif" ||
                 name==L"\"sans-serif\"" ||
                 name==L"arial.ttf")
           wcsncpy(desc.lfFaceName,L"arial",LF_FACESIZE);
        else if (name==L"_monospace" ||
                 name==L"\"monospace\"" ||
                 name==L"_typewriter" ||
                 name==L"courier.ttf")
           wcsncpy(desc.lfFaceName,L"courier",LF_FACESIZE);
        else
           return 0;
     }

     int bad =  EnumFontFamiliesExW(sgFontDC, &desc, MyEnumFontFunc, 0, 0 );
     if (!bad)
        break;
   }

   if (!sgFontDC)
   {
      sgFontDC = CreateCompatibleDC(0);
      SetBkColor(sgFontDC, RGB(0,0,0));
      SetTextColor(sgFontDC, RGB(255,255,255));
      SetTextAlign( sgFontDC, TA_TOP );
   }


   HFONT hfont = CreateFontIndirectW( &desc );
   if (!hfont)
     return 0;

   return new GDIFont(hfont,height, inFormat.bold, inFormat.italic);
}

} // end namespace nme
