#include <Font.h>
#include <Foundation/NSObject.h>
#include <UIKit/UIKit.h>
#include <UIKit/UIFont.h>
#include <Utils.h>



namespace nme
{

// TODO: Is this really the best way of doing it? Also, not a 1:1 mapping.
// From: http://partners.adobe.com/public/developer/en/opentype/glyphlist.txt
static const char *gGlyphNames[] = {
"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "space", "exclam", "quotedbl", "numbersign", "dollar", "percent", "ampersand", "quotesingle", "parenleft", "parenright", "asterisk", "plus", "comma", "hyphen", "period", "slash", "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "colon", "semicolon", "less", "equal", "greater", "question", "at", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "bracketleft", "backslash", "bracketright", "asciicircum", "underscore", "grave", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "braceleft", "verticalbar", "braceright", "asciitilde", "controlDEL", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "nonbreakingspace", "exclamdown", "cent", "sterling", "currency", "yen", "brokenbar", "section", "dieresis", "copyright", "ordfeminine", "guillemotleft", "logicalnot", "softhyphen", "registered", "overscore", "degree", "plusminus", "twosuperior", "threesuperior", "acute", "mu1", "paragraph", "periodcentered", "cedilla", "onesuperior", "ordmasculine", "guillemotright", "onequarter", "onehalf", "threequarters", "questiondown", "Agrave", "Aacute", "Acircumflex", "Atilde", "Adieresis", "Aring", "AE", "Ccedilla", "Egrave", "Eacute", "Ecircumflex", "Edieresis", "Igrave", "Iacute", "Icircumflex", "Idieresis", "Eth", "Ntilde", "Ograve", "Oacute", "Ocircumflex", "Otilde", "Odieresis", "multiply", "Oslash", "Ugrave", "Uacute", "Ucircumflex", "Udieresis", "Yacute", "Thorn", "germandbls", "agrave", "aacute", "acircumflex", "atilde", "adieresis", "aring", "ae", "ccedilla", "egrave", "eacute", "ecircumflex", "edieresis", "igrave", "iacute", "icircumflex", "idieresis", "eth", "ntilde", "ograve", "oacute", "ocircumflex", "otilde", "odieresis", "divide", "oslash", "ugrave", "uacute", "ucircumflex", "udieresis", "yacute", "thorn", "ydieresis", };


class NativeFont : public FontFace
{
   UIFont *mFont;
   CGFont *mCGFont;
   TextLineMetrics mMetrics;
   int    mHeight;
   bool   mOk;

public:
   NativeFont(const Optional<WString>  &inName, bool inBold, int inHeight)
   {
      mCGFont = 0;
      mFont = 0;
      mHeight = inHeight;
      memset(&mMetrics,0,sizeof(mMetrics));

      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      // NSString *path = [[NSBundle mainBundle] pathForResource:str ofType:nil];

      if (!inName.IsSet() || !inName.Get().size())
      {
         mFont = inBold ? [UIFont boldSystemFontOfSize:inHeight] : [UIFont systemFontOfSize:inHeight] ;
      }
      else
      {
         std::string name = WideToUTF8(inName.Get());
         if (!strcasecmp(name.c_str(),"times"))
         {
            name = inBold ? "TimesNewRomanPS-BoldMT" : "Times New Roman";
         }
         else
         {
            if (inBold)
               name += "-Bold";

            bool found = false;
            // Find case match ...
            for(int pass=0;pass<2 && !found;pass++)
            {
               std::string sought = pass==0 ? name : name+"MT";
               NSArray *familyNames = [[NSArray alloc] initWithArray:[UIFont familyNames]];
               NSArray *fontNames;
               NSInteger family, j;
               int numFamilies = [familyNames count];
               for (family=0; family < numFamilies; ++family)
               {
                   fontNames = [[NSArray alloc] initWithArray:
                                     [UIFont fontNamesForFamilyName: [familyNames objectAtIndex: family]]];
                   for (j=0; j<[fontNames count]; ++j)
                   {
                      const char *font = [[fontNames objectAtIndex:j] UTF8String];
                      //printf("Font : %s\n", font);
                      if (!strcasecmp(font,sought.c_str()))
                      {
                         found = true;
                         name = font;
                      }
                   }
                   [fontNames release];
               }
               [familyNames release];
            }
         }
   

         NSString *str = [[NSString alloc] initWithUTF8String:name.c_str()];
         mFont = [UIFont fontWithName:str size:inHeight];
         //printf("Font name : %s = %p\n", name.c_str(), str);

         if (!mFont)
         {
             //printf("Trying font from file %s ...\n", [str UTF8String]);
             // Could not find installed font - try one in file...
             str = [[NSString alloc] initWithUTF8String:(gAssetBase+name).c_str()];
             NSString *fontPath = [[NSBundle mainBundle] pathForResource:str ofType:@"ttf"]; 

             if (fontPath)
             {
                CGDataProviderRef fontDataProvider = CGDataProviderCreateWithFilename([fontPath UTF8String]);
                //printf("Got fontDataProvider %p\n", fontDataProvider);

                if (fontDataProvider)
                {
                   // Create the font with the data provider, then release the data provider.
                   mCGFont = CGFontCreateWithDataProvider(fontDataProvider);
                   //printf("Got font %p\n", mCGFont);
                   CGDataProviderRelease(fontDataProvider); 

                }
             }
         }
      }

      if (mFont)
      {
         mMetrics.ascent = (int)[ mFont ascender ];
         mMetrics.descent = -(int)[ mFont descender ];
         if ([mFont respondsToSelector: NSSelectorFromString(@"lineHeight")])
            mMetrics.height = (int)[ mFont lineHeight ];
         else
            mMetrics.height = (int)[ mFont leading ];
         //printf("mFont metrics %f/%f/%f\n",  mMetrics.ascent,  mMetrics.descent ,  mMetrics.height );
      }
      else if (mCGFont)
      {
         int m = CGFontGetUnitsPerEm ( mCGFont );

         //CGRect CGFontGetFontBBox ( CGFontRef font );

         mMetrics.ascent = (int)((double)CGFontGetAscent( mCGFont )*mHeight/m);
         mMetrics.descent = -(int)((double)CGFontGetDescent( mCGFont )*mHeight/m);
         mMetrics.height = mHeight; //CGFontGetXHeight( mCGFont );
         //printf("mCGFont metrics %f/%f/%f (%d)\n",  mMetrics.ascent,  mMetrics.descent ,  mMetrics.height, m );
      }
      else
      {
         //printf("No native font\n");
      }
 
      //printf("Loaded native font : %p\n", mFont);
      if (mFont)
         [mFont retain];
      [pool drain];
   }

   bool IsOk() { return mFont || mCGFont; }

   ~NativeFont()
   {
      if (mFont) [mFont release];
      if (mCGFont)
         CGFontRelease( mCGFont );
   }

   bool IsNative() { return true; }

   bool GetGlyphInfo(int inChar, int &outW, int &outH, int &outAdvance, int &outOx, int &outOy)
   {
      wchar_t buf[] = { inChar, 0 };
      NSString *str = [[NSString alloc] initWithUTF8String:WideToUTF8(buf).c_str()];
      CGSize stringSize;
      if (mFont)
      {
         stringSize = [str sizeWithFont:mFont];
         outW  = stringSize.width;
         outH  = stringSize.height;
         outOx = 0;
         outOy = -(int)mMetrics.ascent;
         outAdvance = stringSize.width;
         //printf("%d (%c)  %d,%d %dx%d\n",inChar,inChar, outOx, outOy, outW, outH);
         return true;
      }
      else if (mCGFont)
      {
         CGGlyph glyph = 0;
         if (inChar<256)
         {
            NSString *str = [[NSString alloc] initWithUTF8String:gGlyphNames[inChar]];
            glyph = CGFontGetGlyphWithGlyphName(mCGFont, (__CFString *)str);
         }
         /*
         printf("Got glyph (%c) %d!\n",inChar,glyph);
         static bool first = true;
         if (first)
         {
            for(int i=0;i<CGFontGetNumberOfGlyphs(mCGFont);i++)
            {
               CFStringRef name = CGFontCopyGlyphNameForGlyph(mCGFont, i );
               printf("Contains : %d ] %s\n", i, CFStringGetCStringPtr(name,CFStringGetSystemEncoding()) );
            }
            first = false;
         }
         */


         CGRect bbox;
         CGFontGetGlyphBBoxes ( mCGFont, &glyph, 1, &bbox );
         int advance = 0;
         CGFontGetGlyphAdvances ( mCGFont, &glyph, 1, &advance );

         int m = CGFontGetUnitsPerEm ( mCGFont );
         //printf("Bounds : %f,%f  %fx%f / %d\n",
            //bbox.origin.x, bbox.origin.y, bbox.size.width, bbox.size.height, advance );

         //printf("GlyphInfoSize : %f,%f\n", stringSize.width, stringSize.height);
         outW  = (int)(bbox.size.width*mHeight/m + 0.99);
         outH  = (int)(bbox.size.height*mHeight/m + 0.99);
         if (outW*outH==0)
            outW = outH = 1;
         outOx = (int)(bbox.origin.x*mHeight/m+0.5);
         outOy = -(int)((bbox.size.height+bbox.origin.y)*mHeight/m + 0.99);
         outAdvance = advance*mHeight/m;
 
         return true;
      }

      return false;
  }

   void RenderGlyph(int inChar,const RenderTarget &outTarget)
   {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

      CGSize size = CGSizeMake(outTarget.mRect.w, outTarget.mRect.h);
      // Create a context to render into.
      //printf("Drawing at size %dx%d...\n", outTarget.mRect.w, outTarget.mRect.h);
      UIGraphicsBeginImageContext(size);
   
      CGPoint textOrigin = CGPointMake(0,0);
   
      wchar_t buf[] = { inChar, 0 };
      NSString *str = [[NSString alloc] initWithUTF8String:WideToUTF8(buf).c_str()];
      
      // Draw the string into out image!
      if (mFont)
      {
         [str drawAtPoint:textOrigin withFont:mFont];
      }
      else if (mCGFont)
      {
         CGGlyph glyph = 0;
         if (inChar<256)
         {
            NSString *str = [[NSString alloc] initWithUTF8String:gGlyphNames[inChar]];
            glyph = CGFontGetGlyphWithGlyphName(mCGFont, (__CFString *)str);
         }
         //printf("Glyph : %c (%c) name = %s\n", inChar, inChar, gGlyphNames[inChar]);

         CGRect bbox;
         CGFontGetGlyphBBoxes ( mCGFont, &glyph, 1, &bbox );
         int advance = 0;
         CGFontGetGlyphAdvances ( mCGFont, &glyph, 1, &advance );
         int m = CGFontGetUnitsPerEm ( mCGFont );
 
         CGContextRef context = UIGraphicsGetCurrentContext();
         CGContextSetFont(context, mCGFont);
         CGContextSetFontSize(context, mHeight);

         // Font rendering is otherwise upsidedown
         CGContextTranslateCTM ( context, -bbox.origin.x*mHeight/m, 
                                 (bbox.size.height+bbox.origin.y)*mHeight/m );
         CGContextScaleCTM ( context, 1.0, -1.0 );
         CGContextSetShouldSmoothFonts(context,true);
         CGContextSetShouldSubpixelPositionFonts(context,false);
         CGFloat stroke[] = { 0,0,0,0 };
         CGContextSetStrokeColor(context,stroke);
         //CGContextSetInterpolationQuality(context,kCGInterpolationHigh);
         //CGContextSetShouldAntialias(context,false);

         CGContextSetTextDrawingMode(context,kCGTextFill);
         CGContextShowGlyphsAtPoint(context,0,0,&glyph,1);
      }
   

      // Get a raw bitmap of what we've drawn.
      CGImageRef maskImage = [UIGraphicsGetImageFromCurrentImageContext() CGImage];
      CFDataRef imageData = CGDataProviderCopyData( CGImageGetDataProvider(maskImage));

      uint8_t *bitmap = (uint8_t *)CFDataGetBytePtr(imageData);
      size_t rowBytes = CGImageGetBytesPerRow(maskImage);

      static int gamma_lut[256];
      static bool is_init = false;
      if (!is_init)
      {
         is_init = true;
         for(int i=0;i<256;i++)
            gamma_lut[i] = i*i/(255);
      }
   
      for(int y=0;y<size.height;y++)
      {
          uint8_t *src = bitmap + rowBytes*y + 3;
          uint8  *dest = (uint8 *)outTarget.Row(y + outTarget.mRect.y) + outTarget.mRect.x;
          for(int x=0;x<size.width;x++)
          {
             // printf( *src ? "X" : ".");
             *dest++ = mCGFont ? gamma_lut[*src] : *src;
             src+=4;
          }
          // printf("\n");
      }
      CFRelease(imageData); // We're done with this data now.

      UIGraphicsEndImageContext();

      [pool drain];
   }

   void UpdateMetrics(TextLineMetrics &ioMetrics)
   {
      ioMetrics.ascent = std::max( ioMetrics.ascent, (float)mMetrics.ascent);
      ioMetrics.descent = std::max( ioMetrics.descent, (float)mMetrics.descent);
      ioMetrics.height = std::max( ioMetrics.height, (float)mMetrics.height);
   }

   int  Height()
   {
      return mHeight;
   }

};



FontFace *FontFace::CreateNative(const TextFormat &inFormat,double inScale)
{
   int height = (int)( 0.5 + inFormat.size*inScale );
   NativeFont *face = new NativeFont(inFormat.font,inFormat.bold,height);
   if (face->IsOk())
      return face;
   delete face;
   return 0;
}

}


