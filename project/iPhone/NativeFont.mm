#include <Font.h>
#include <Foundation/NSObject.h>
#include <UIKit/UIKit.h>
#include <UIKit/UIFont.h>
#include <Utils.h>



namespace nme
{

// TODO: Is this really the best way of doing it? Also, not a 1:1 mapping.
// From: http://partners.adobe.com/public/developer/en/opentype/glyphlist.txt

// Worst. API. Ever.
static const char *gGlyphNames[] = {
"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "space", "exclam", "quotedbl", "numbersign", "dollar", "percent", "ampersand", "quotesingle", "parenleft", "parenright", "asterisk", "plus", "comma", "hyphen", "period", "slash", "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "colon", "semicolon", "less", "equal", "greater", "question", "at", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "bracketleft", "backslash", "bracketright", "asciicircum", "underscore", "grave", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "braceleft", "verticalbar", "braceright", "asciitilde", "controlDEL", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "nonbreakingspace", "exclamdown", "cent", "sterling", "currency", "yen", "brokenbar", "section", "dieresis", "copyright", "ordfeminine", "guillemotleft", "logicalnot", "softhyphen", "registered", "overscore", "degree", "plusminus", "twosuperior", "threesuperior", "acute", "mu1", "paragraph", "periodcentered", "cedilla", "onesuperior", "ordmasculine", "guillemotright", "onequarter", "onehalf", "threequarters", "questiondown", "Agrave", "Aacute", "Acircumflex", "Atilde", "Adieresis", "Aring", "AE", "Ccedilla", "Egrave", "Eacute", "Ecircumflex", "Edieresis", "Igrave", "Iacute", "Icircumflex", "Idieresis", "Eth", "Ntilde", "Ograve", "Oacute", "Ocircumflex", "Otilde", "Odieresis", "multiply", "Oslash", "Ugrave", "Uacute", "Ucircumflex", "Udieresis", "Yacute", "Thorn", "germandbls", "agrave", "aacute", "acircumflex", "atilde", "adieresis", "aring", "ae", "ccedilla", "egrave", "eacute", "ecircumflex", "edieresis", "igrave", "iacute", "icircumflex", "idieresis", "eth", "ntilde", "ograve", "oacute", "ocircumflex", "otilde", "odieresis", "divide", "oslash", "ugrave", "uacute", "ucircumflex", "udieresis", "yacute", "thorn", "ydieresis", };



// Try some code lifted from:
// http://code.google.com/p/cocos2d-iphone/source/browse/trunk/external/FontLabel/FontLabelStringDrawing.m
// Thanks a lot !!!!!!!!

#define kUnicodeHighSurrogateStart 0xD800
#define kUnicodeHighSurrogateEnd 0xDBFF
#define kUnicodeLowSurrogateStart 0xDC00
#define kUnicodeLowSurrogateEnd 0xDFFF
#define UnicharIsHighSurrogate(c) (c >= kUnicodeHighSurrogateStart && c <= kUnicodeHighSurrogateEnd)
#define UnicharIsLowSurrogate(c) (c >= kUnicodeLowSurrogateStart && c <= kUnicodeLowSurrogateEnd)
#define ConvertSurrogatePairToUTF32(high, low) ((UInt32)((high - 0xD800) * 0x400 + (low - 0xDC00) + 0x10000))



typedef enum {
        kFontTableFormat4 = 4,
        kFontTableFormat12 = 12,
} FontTableFormat;

struct GroupStruct
{
  UInt32 startCharCode;
  UInt32 endCharCode;
  UInt32 startGlyphCode;
};
 

typedef struct fontTable {
        CFDataRef cmapTable;
        FontTableFormat format;
        union {
                struct {
                        UInt16 segCountX2;
                        UInt16 *endCodes;
                        UInt16 *startCodes;
                        UInt16 *idDeltas;
                        UInt16 *idRangeOffsets;
                } format4;
                struct {
                        UInt32 nGroups;
                        GroupStruct *groups;
                } format12;
        } cmap;
} fontTable;


static FontTableFormat supportedFormats[] = { kFontTableFormat4, kFontTableFormat12 };
static size_t supportedFormatsCount = sizeof(supportedFormats) / sizeof(FontTableFormat);


static fontTable *newFontTable(CFDataRef cmapTable, FontTableFormat format) {
        fontTable *table = (struct fontTable *)malloc(sizeof(struct fontTable));
        table->cmapTable = (CFDataRef)CFRetain(cmapTable);
        table->format = format;
        return table;
}


static void freeFontTable(fontTable *table) {
        if (table != NULL) {
                CFRelease(table->cmapTable);
                free(table);
        }
}


// read the cmap table from the font
// we only know how to understand some of the table formats at the moment
static fontTable *readFontTableFromCGFont(CGFontRef font) {
        CFDataRef cmapTable = CGFontCopyTableForTag(font, 'cmap');
        if (cmapTable==NULL)
        {
            //printf("No cmap table.\n");
            return 0;
        }
        const UInt8 * const bytes = CFDataGetBytePtr(cmapTable);
        if (OSReadBigInt16(bytes, 0) != 0)
        {
           //printf("No header\n");
           return 0;
        }

        UInt16 numberOfSubtables = OSReadBigInt16(bytes, 2);
        const UInt8 *unicodeSubtable = NULL;
        //UInt16 unicodeSubtablePlatformID;
        UInt16 unicodeSubtablePlatformSpecificID;
        FontTableFormat unicodeSubtableFormat;
        const UInt8 * const encodingSubtables = &bytes[4];
        for (UInt16 i = 0; i < numberOfSubtables; i++) {
                const UInt8 * const encodingSubtable = &encodingSubtables[8 * i];
                UInt16 platformID = OSReadBigInt16(encodingSubtable, 0);
                UInt16 platformSpecificID = OSReadBigInt16(encodingSubtable, 2);
                // find the best subtable
                // best is defined by a combination of encoding and format
                // At the moment we only support format 4, so ignore all other format tables
                // We prefer platformID == 0, but we will also accept Microsoft's unicode format
                if (platformID == 0 || (platformID == 3 && platformSpecificID == 1)) {
                        BOOL preferred = NO;
                        if (unicodeSubtable == NULL) {
                                preferred = YES;
                        } else if (platformID == 0 && platformSpecificID > unicodeSubtablePlatformSpecificID) {
                                preferred = YES;
                        }
                        if (preferred) {
                                UInt32 offset = OSReadBigInt32(encodingSubtable, 4);
                                const UInt8 *subtable = &bytes[offset];
                                UInt16 format = OSReadBigInt16(subtable, 0);
                                for (int i = 0; i < supportedFormatsCount; i++) {
                                        if (format == supportedFormats[i]) {
                                                if (format >= 8) {
                                                        // the version is a fixed-point
                                                        UInt16 formatFrac = OSReadBigInt16(subtable, 2);
                                                        if (formatFrac != 0) {
                                                                // all the current formats with a Fixed version are always *.0
                                                                continue;
                                                        }
                                                }
                                                unicodeSubtable = subtable;
                                                //unicodeSubtablePlatformID = platformID;
                                                unicodeSubtablePlatformSpecificID = platformSpecificID;
                                                unicodeSubtableFormat = (FontTableFormat)format;
                                                break;
                                        }
                                }
                        }
                }
        }
        fontTable *table = NULL;
        if (unicodeSubtable != NULL) {
                table = newFontTable(cmapTable, unicodeSubtableFormat);
                switch (unicodeSubtableFormat) {
                        case kFontTableFormat4:
                                // subtable format 4
                                //UInt16 length = OSReadBigInt16(unicodeSubtable, 2);
                                //UInt16 language = OSReadBigInt16(unicodeSubtable, 4);
                                table->cmap.format4.segCountX2 = OSReadBigInt16(unicodeSubtable, 6);
                                //UInt16 searchRange = OSReadBigInt16(unicodeSubtable, 8);
                                //UInt16 entrySelector = OSReadBigInt16(unicodeSubtable, 10);
                                //UInt16 rangeShift = OSReadBigInt16(unicodeSubtable, 12);
                                table->cmap.format4.endCodes = (UInt16*)&unicodeSubtable[14];
                                table->cmap.format4.startCodes = (UInt16*)&((UInt8*)table->cmap.format4.endCodes)[table->cmap.format4.segCountX2+2];
                                table->cmap.format4.idDeltas = (UInt16*)&((UInt8*)table->cmap.format4.startCodes)[table->cmap.format4.segCountX2];
                                table->cmap.format4.idRangeOffsets = (UInt16*)&((UInt8*)table->cmap.format4.idDeltas)[table->cmap.format4.segCountX2];
                                //UInt16 *glyphIndexArray = &idRangeOffsets[segCountX2];
                                break;
                        case kFontTableFormat12:
                                table->cmap.format12.nGroups = OSReadBigInt32(unicodeSubtable, 12);
                                table->cmap.format12.groups = (GroupStruct *)&unicodeSubtable[16];
                                break;
                        default:
                                freeFontTable(table);
                                table = NULL;
                }
        }
        CFRelease(cmapTable);
        return table;
}


// outGlyphs must be at least size n
static void mapCharactersToGlyphsInFont(const fontTable *table, unichar characters[], size_t charLen, CGGlyph outGlyphs[], size_t *outGlyphLen) {
        if (table != NULL) {
                NSUInteger j = 0;
                for (NSUInteger i = 0; i < charLen; i++, j++) {
                        unichar c = characters[i];
                        switch (table->format) {
                                case kFontTableFormat4: {
                                        UInt16 segOffset;
                                        BOOL foundSegment = NO;
                                        for (segOffset = 0; segOffset < table->cmap.format4.segCountX2; segOffset += 2) {
                                                UInt16 endCode = OSReadBigInt16(table->cmap.format4.endCodes, segOffset);
                                                if (endCode >= c) {
                                                        foundSegment = YES;
                                                        break;
                                                }
                                        }
                                        if (!foundSegment) {
                                                // no segment
                                                // this is an invalid font
                                                outGlyphs[j] = 0;
                                        } else {
                                                UInt16 startCode = OSReadBigInt16(table->cmap.format4.startCodes, segOffset);
                                                if (!(startCode <= c)) {
                                                        // the code falls in a hole between segments
                                                        outGlyphs[j] = 0;
                                                } else {
                                                        UInt16 idRangeOffset = OSReadBigInt16(table->cmap.format4.idRangeOffsets, segOffset);
                                                        if (idRangeOffset == 0) {
                                                                UInt16 idDelta = OSReadBigInt16(table->cmap.format4.idDeltas, segOffset);
                                                                outGlyphs[j] = (c + idDelta) % 65536;
                                                        } else {
                                                                // use the glyphIndexArray
                                                                UInt16 glyphOffset = idRangeOffset + 2 * (c - startCode);
                                                                outGlyphs[j] = OSReadBigInt16(&((UInt8*)table->cmap.format4.idRangeOffsets)[segOffset], glyphOffset);
                                                        }
                                                }
                                        }
                                        break;
                                }
                                case kFontTableFormat12: {
                                        UInt32 c32 = c;
                                        if (UnicharIsHighSurrogate(c)) {
                                                if (i+1 < charLen) { // do we have another character after this one?
                                                        unichar cc = characters[i+1];
                                                        if (UnicharIsLowSurrogate(cc)) {
                                                                c32 = ConvertSurrogatePairToUTF32(c, cc);
                                                                i++;
                                                        }
                                                }
                                        }
                                        for (UInt32 idx = 0;; idx++) {
                                                if (idx >= table->cmap.format12.nGroups) {
                                                        outGlyphs[j] = 0;
                                                        break;
                                                }
                                                __typeof__(table->cmap.format12.groups[idx]) group = table->cmap.format12.groups[idx];
                                                if (c32 >= OSSwapBigToHostInt32(group.startCharCode) && c32 <= OSSwapBigToHostInt32(group.endCharCode)) {
                                                        outGlyphs[j] = (CGGlyph)(OSSwapBigToHostInt32(group.startGlyphCode) + (c32 - OSSwapBigToHostInt32(group.startCharCode)));
                                                        break;
                                                }
                                        }
                                        break;
                                }
                        }
                }
                if (outGlyphLen != NULL) *outGlyphLen = j;
        } else {
                // we have no table, so just null out the glyphs
                bzero(outGlyphs, charLen*sizeof(CGGlyph));
                if (outGlyphLen != NULL) *outGlyphLen = 0;
        }
}






class NativeFont : public FontFace
{
   UIFont *mFont;
   CGFont *mCGFont;
   TextLineMetrics mMetrics;
   fontTable *mFontTable;
   int    mHeight;
   bool   mOk;

public:
   NativeFont(const Optional<WString>  &inName, bool inBold, int inHeight)
   {
      mCGFont = 0;
      mFont = 0;
      mHeight = inHeight;
      memset(&mMetrics,0,sizeof(mMetrics));
      mFontTable = 0;

      #ifndef OBJC_ARC
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      #endif
      // NSString *path = [[NSBundle mainBundle] pathForResource:str ofType:nil];

      if (!inName.IsSet() || !inName.Get().size())
      {
         mFont = inBold ? [UIFont boldSystemFontOfSize:inHeight] : [UIFont systemFontOfSize:inHeight] ;
      }
      else
      {
         std::string name = WideToUTF8(inName.Get());
         if (!strcasecmp(name.c_str(),"times") || !strcasecmp(name.c_str(),"_serif"))
         {
            name = inBold ? "TimesNewRomanPS-BoldMT" : "Times New Roman";
         }
		 else if (!strcasecmp(name.c_str(),"_sans"))
		 {
			name = inBold ? "Helvetica-Bold" : "Helvetica";
		 }
		 else if (!strcasecmp(name.c_str(),"_typewriter"))
		 {
			name = inBold ? "CourierNewPS-BoldMT" : "CourierNewPSMT";
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
                   #ifndef OBJC_ARC
                   [fontNames release];
                   #endif
               }
               #ifndef OBJC_ARC
               [familyNames release];
               #endif
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
             NSString *fontPath = [[NSBundle mainBundle] pathForResource:str ofType:nil]; 

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
      #ifndef OBJC_ARC
      if (mFont)
         [mFont retain];
      [pool drain];
      #endif
   }

   bool IsOk() { return mFont || mCGFont; }

   ~NativeFont()
   {
      if (mFontTable)
        freeFontTable(mFontTable);
      #ifndef OBJC_ARC
      if (mFont) [mFont release];
      #endif
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
         CGGlyph glyph = GetGlyphFromCGFont(inChar);
         //printf("Got glyph (%c) %d!\n",inChar,glyph);

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

   int GetGlyphFromCGFont(unichar inChar)
   {
      if (inChar<256)
      {
         NSString *str = [[NSString alloc] initWithUTF8String:gGlyphNames[inChar]];
         #ifndef OBJC_ARC
         int glyph = CGFontGetGlyphWithGlyphName(mCGFont, (__CFString *)str);
         #else
         int glyph = CGFontGetGlyphWithGlyphName(mCGFont, (__bridge __CFString *)str);
         #endif

         if (glyph>0)
           return glyph;

         /*
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
      }
 

      //printf("GetGlyphFromCGFont %d...\n", inChar);
      if (!mFontTable)
      {
         mFontTable = readFontTableFromCGFont(mCGFont);
         //printf("Created : %p\n", mFontTable);
      }
      if (!mFontTable)
        return 0;

      CGGlyph results[4] = { 0 };
      size_t size = 4;
      mapCharactersToGlyphsInFont(mFontTable, &inChar, 1, results, &size);
      //printf("Got results %d/%d\n", size,results[0]);
      if (size>0)
        return results[0];

      return 0;
   }

   void RenderGlyph(int inChar,const RenderTarget &outTarget)
   {
      #ifndef OBJC_ARC
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      #endif
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
         // Worst. API. Ever.
         CGGlyph glyph = GetGlyphFromCGFont(inChar);
         //printf("Glyph : %d (%c) name = %s\n", glyph, inChar, inChar<256? gGlyphNames[inChar] : "");

         CGRect bbox;
         CGFontGetGlyphBBoxes ( mCGFont, &glyph, 1, &bbox );
         int m = CGFontGetUnitsPerEm ( mCGFont );
         //printf("BBox %f,%f  %fx%f\n", bbox.origin.x/m, bbox.origin.y/m, bbox.size.width/m, bbox.size.height/m );

      
         int advance = 0;
         CGFontGetGlyphAdvances ( mCGFont, &glyph, 1, &advance );
 
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
      #ifndef OBJC_ARC
      [pool drain];
      #endif
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


