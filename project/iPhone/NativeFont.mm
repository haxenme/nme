#include <Font.h>
#include <Foundation/NSObject.h>
#include <UIKit/UIKit.h>
#include <UIKit/UIFont.h>
#include <Utils.h>



namespace nme
{


class NativeFont : public FontFace
{
   UIFont *mFont;
   CGFont *mCGFont;
   int    mHeight;
   bool   mOk;

public:
   NativeFont(const Optional<WString>  &inName, bool inBold, int inHeight)
   {
      mCGFont = 0;
      mFont = 0;
      mHeight = inHeight;
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      // NSString *path = [[NSBundle mainBundle] pathForResource:str ofType:nil];

      if (!inName.IsSet() || !inName.Get().size())
         mFont = inBold ? [UIFont boldSystemFontOfSize:inHeight] : [UIFont systemFontOfSize:inHeight] ;
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
   
         //printf("name : %s\n", name.c_str());

         NSString *str = [[NSString alloc] initWithUTF8String:("assets/"+name).c_str()];
         mFont = [UIFont fontWithName:str size:inHeight];

         if (!mFont)
         {
             //printf("Trying font from file %s ...\n", [str UTF8String]);
             // Could not find installed font - try one in file...
             NSString *fontPath = [[NSBundle mainBundle] pathForResource:str ofType:@"ttf"]; 
             //printf("in path %s...\n", [fontPath UTF8String]);

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
         stringSize = [str sizeWithFont:mFont];
      else
      {
         UniChar code = inChar;
         CFStringRef name = CFStringCreateWithCharacters (0,&code,1);
         CGGlyph glyph = CGFontGetGlyphWithGlyphName(mCGFont, name);
         //printf("Got glyph %d!\n",glyph);

         CGSize size = CGSizeMake(mHeight*2,mHeight);
         // Create a context to render into.
         UIGraphicsBeginImageContext(size);

         CGContextRef context = UIGraphicsGetCurrentContext();
         CGContextSetFont(context, mCGFont);
         CGContextSetFontSize(context, mHeight);

         CGContextSetTextDrawingMode(context,kCGTextInvisible);
         CGContextShowGlyphsAtPoint(context,0,0,&glyph,1);
         CGPoint pos = CGContextGetTextPosition (context);
         stringSize.width = pos.x;
         stringSize.height = mHeight;
         UIGraphicsEndImageContext();
      }
      //printf("GlyphInfoSize : %f,%f\n", stringSize.width, stringSize.height);
      outW  = stringSize.width;
      outH  = stringSize.height;
      outOx = 0;
      outOy = 0;
      outAdvance = stringSize.width;
      return true;
   }

   void RenderGlyph(int inChar,const RenderTarget &outTarget)
   {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

      CGSize size = CGSizeMake(outTarget.mRect.w, outTarget.mRect.h);
      // Create a context to render into.
      UIGraphicsBeginImageContext(size);
   
      CGPoint textOrigin = CGPointMake(0,0);
   
      wchar_t buf[] = { inChar, 0 };
      NSString *str = [[NSString alloc] initWithUTF8String:WideToUTF8(buf).c_str()];
      
      // Draw the string into out image!
      if (mFont)
         [str drawAtPoint:textOrigin withFont:mFont];
      else if (mCGFont)
      {
         CGContextRef context = UIGraphicsGetCurrentContext();
         UniChar code = inChar;
         CFStringRef name = CFStringCreateWithCharacters (0,&code,1);
         CGGlyph glyph = CGFontGetGlyphWithGlyphName(mCGFont, name);

         CGContextSetFont(context, mCGFont);
         CGContextSetFontSize(context, mHeight);

         // Font rendering is otherwise upsidedown
         CGContextTranslateCTM ( context, 0, mHeight );
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
             //printf( *src ? "X" : " ");
             *dest++ = mCGFont ? gamma_lut[*src] : *src;
             src+=4;
          }
          //printf("\n");
      }
      CFRelease(imageData); // We're done with this data now.

      UIGraphicsEndImageContext();

      [pool drain];
   }

   void UpdateMetrics(TextLineMetrics &ioMetrics)
   {
      //ioMetrics.ascent = std::max( ioMetrics.ascent, (float)mMetrics.tmAscent);
      //ioMetrics.descent = std::max( ioMetrics.descent, (float)mMetrics.tmDescent);
      //ioMetrics.height = std::max( ioMetrics.height, (float)mMetrics.tmHeight);
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


