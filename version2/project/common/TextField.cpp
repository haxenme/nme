#include <TextField.h>
#include <Tilesheet.h>
#include <Utils.h>
#include <Surface.h>
#include "XML/tinyxml.h"
#include <ctype.h>

namespace nme
{

TextField::TextField(bool inInitRef) : DisplayObject(inInitRef),
   alwaysShowSelection(false),
   antiAliasType(aaNormal),
   autoSize(asNone),
   background(false),
   backgroundColor(0xffffffff),
   border(false),
   borderColor(0x00000000),
   condenseWhite(false),
   defaultTextFormat( TextFormat::Default() ),
   displayAsPassword(false),
   embedFonts(false),
   gridFitType(gftPixel),
   maxChars(0),
   mouseWheelEnabled(true),
   multiline(false),
   restrict(std::wstring()),
   scrollH(0),
   scrollV(0),
   selectable(true),
   sharpness(0),
   styleSheet(0),
   textColor(0x000000),
   thickness(0),
   useRichTextClipboard(false),
   wordWrap(false),
	isInput(false)
{
   mStringState = ssText;
   mLinesDirty = false;
   mGfxDirty = true;
   mRect = Rect(100,100);
   mLastUpdateScale = -1;
   mFontsDirty = false;
}

TextField::~TextField()
{
   defaultTextFormat->DecRef();
}

double TextField::getWidth()
{
   Layout();
   return mRect.w;
}

void TextField::setWidth(double inWidth)
{
   mRect.w = inWidth;
   mLinesDirty = true;
   mGfxDirty = true;
}

double TextField::getHeight()
{
   Layout();
   return mRect.h;
}

void TextField::setHeight(double inHeight)
{
   mRect.h = inHeight;
   mLinesDirty = true;
   mGfxDirty = true;
}

const TextFormat *TextField::getDefaultTextFormat()
{
   return defaultTextFormat;
}

void TextField::setDefaultTextFormat(TextFormat *inFmt)
{
   if (inFmt)
      inFmt->IncRef();
   if (defaultTextFormat)
      defaultTextFormat->DecRef();
   defaultTextFormat = inFmt;
   mLinesDirty = true;
   mGfxDirty = true;
}



void TextField::setTextColor(int inCol)
{
   textColor = inCol;
}

void TextField::setIsInput(bool inIsInput)
{
	isInput = inIsInput;
}

void TextField::setBackground(bool inBackground)
{
	background = inBackground;
	mGfxDirty = true;
	DirtyDown(dirtCache);
}

void TextField::setBackgroundColor(int inBackgroundColor)
{
	backgroundColor = inBackgroundColor;
	mGfxDirty = true;
	DirtyDown(dirtCache);
}

void TextField::setBorder(bool inBorder)
{
	border = inBorder;
	mGfxDirty = true;
	DirtyDown(dirtCache);
}

void TextField::setBorderColor(int inBorderColor)
{
	borderColor = inBorderColor;
	mGfxDirty = true;
	DirtyDown(dirtCache);
}



void TextField::Clear()
{
   for(int i=0;i<mCharGroups.size();i++)
      mCharGroups[i].Clear();
   mCharGroups.resize(0);
   mLines.resize(0);
}

void TextField::setText(const std::wstring &inString)
{
   Clear();
   CharGroup chars;
   chars.mChars = inString.length();
   chars.mFormat = defaultTextFormat->IncRef();
   chars.mFont = 0;
   chars.mFontHeight = 0;
   chars.mNewLines = 0;
   wchar_t *str = new wchar_t[chars.mChars];
   chars.mString = str;
   memcpy(str,inString.c_str(), chars.mChars*sizeof(wchar_t));
   mCharGroups.push_back(chars);
   mLinesDirty = true;
   mFontsDirty = true;
   mGfxDirty = true;
}

std::wstring TextField::getText()
{
   std::wstring result;
   for(int i=0;i<mCharGroups.size();i++)
      result += std::wstring(mCharGroups[i].mString,mCharGroups[i].mChars);
   return result;
}

void TextField::AddNode(const TiXmlNode *inNode, TextFormat *inFormat,int &ioCharCount,
                        int inLineSkips)
{
   for(const TiXmlNode *child = inNode->FirstChild(); child; child = child->NextSibling() )
   {
      const TiXmlText *text = child->ToText();
      if (text)
      {
         CharGroup chars;
         chars.mFormat = inFormat->IncRef();
         chars.mFont = 0;
         chars.mFontHeight = 0;
         int len = 0;
         wchar_t *str = UTF8ToWideCStr(text->Value(),len);
         chars.mString = str;
         chars.mChars = len;
         chars.mNewLines = inLineSkips;
         ioCharCount += len;

         mCharGroups.push_back(chars);
         //printf(" %s %d\n", text->Value(), inLineSkips );
         inLineSkips = 0;
      }
      else
      {
         const TiXmlElement *el = child->ToElement();
         if (el)
         {
            inFormat->IncRef();
            TextFormat *fmt = inFormat;

            if (el->ValueTStr()=="font")
            {
               for (const TiXmlAttribute *att = el->FirstAttribute(); att;
                          att = att->Next())
               {
                  const char *val = att->Value();
                  if (att->NameTStr()=="color" && val[0]=='#')
                  {
                     int col;
                     if (sscanf(val+1,"%x",&col))
                     {
                        fmt = fmt->COW();
                        fmt->color = col;
                     }
                  }
                  else if (att->NameTStr()=="face")
                  {
                     fmt = fmt->COW();
                     fmt->font = UTF8ToWide(val);
                  }
                  else if (att->NameTStr()=="size")
                  {
                     int size;
                     if (sscanf(att->Value(),"%d",&size))
                     {
                        fmt = fmt->COW();
                        if (val[0]=='-' || val[0]=='+')
                           fmt->size = std::max( (int)fmt->size + size, 0 );
                        else
                           fmt->size = size;
                     }
                  }
               }
            }
            else if (el->ValueTStr()=="b")
            {
               if (!fmt->bold)
               {
                  fmt = fmt->COW();
                  fmt->bold = true;
               }
            }
            else if (el->ValueTStr()=="i")
            {
               if (!fmt->italic)
               {
                  fmt = fmt->COW();
                  fmt->italic = true;
               }
            }
            else if (el->ValueTStr()=="u")
            {
               if (!fmt->underline)
               {
                  fmt = fmt->COW();
                  fmt->underline = true;
               }
            }
            else if (el->ValueTStr()=="br")
               inLineSkips++;
            else if (el->ValueTStr()=="p")
               inLineSkips++;


            AddNode(child,fmt,ioCharCount,inLineSkips);

            inFormat->DecRef();
         }
      }
   }
}


void TextField::setHTMLText(const std::wstring &inString)
{
   Clear();
   mLinesDirty = true;
   mFontsDirty = true;
   std::string str = "<top>" + WideToUTF8(inString) + "</top>";

   TiXmlNode::SetCondenseWhiteSpace(condenseWhite);
   TiXmlDocument doc;
   const char *err = doc.Parse(str.c_str(),0,TIXML_ENCODING_UTF8);
   const TiXmlNode *top =  doc.FirstChild();
   if (top)
   {
      int chars = 0;
      AddNode(top,defaultTextFormat,chars,0);
   }
}


void TextField::UpdateFonts(const Transform &inTransform)
{
   double scale = inTransform.mMatrix->GetScaleY();// * inTransform->mStageScaleY;
	GlyphRotation rot = fabs(inTransform.mMatrix->m00)<0.0001 ?
	                         (inTransform.mMatrix->m01 > 0 ? gr90 : gr270 ) :
	                      (inTransform.mMatrix->m00 > 0 ? gr0 : gr180 );

   if (mFontsDirty || scale!=mLastUpdateScale || rot!=mLastUpdateRotation)
   {
      for(int i=0;i<mCharGroups.size();i++)
         if (mCharGroups[i].UpdateFont(scale,rot,!embedFonts))
            mLinesDirty = true;
      mFontsDirty = false;
      mLastUpdateScale = scale;
      mLastUpdateRotation = rot;
   }
}


void TextField::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inTarget.mPixelFormat==pfAlpha)
      return;

   UpdateFonts(inState.mTransform);
   Layout();

	if (inState.mPhase==rpHitTest)
	{
		UserPoint pos =  inState.mTransform.mMatrix->ApplyInverse(
				UserPoint(inState.mClipRect.x, inState.mClipRect.y) );
		if ( mRect.Contains(pos) )
			inState.mHitResult = this;
		return;
	}

   Graphics &gfx = GetGraphics();
   if (mGfxDirty)
   {
      gfx.clear();
      if (background || border)
		{
         int b=2;
         if (background)
            gfx.beginFill( backgroundColor, 1.0 );
         if (border)
            gfx.lineStyle(1, borderColor );
         gfx.moveTo(mRect.x-b,mRect.y-b);
         gfx.lineTo(mRect.x+b+mRect.w,mRect.y-b);
         gfx.lineTo(mRect.x+b+mRect.w,mRect.y+b+mRect.h);
         gfx.lineTo(mRect.x-b,mRect.y+b+mRect.h);
         gfx.lineTo(mRect.x-b,mRect.y-b);
      }
      mGfxDirty = false;
   }

   if (!gfx.empty())
   {
      gfx.Render(inTarget,inState);
   }

   const Matrix &matrix = *inState.mTransform.mMatrix;
   // The fonts have already been scaled by sy ...
   double sy = matrix.GetScaleY();
   if (sy!=0) sy = 1.0/sy;
   UserPoint origin = matrix.Apply( mRect.x,mRect.y );
   UserPoint dPdX = UserPoint( matrix.m00*sy, matrix.m10*sy );
   UserPoint dPdY = UserPoint( matrix.m01*sy, matrix.m11*sy );

   int last_x = mRect.w;
   // TODO: this for teh rotated-90 cases too
   RenderTarget target;
   if (dPdX.y==0 && dPdY.x==0)
   {
      Rect rect = mRect.Translated(origin.x,origin.y).Intersect(inState.mClipRect);
      if (inState.mMask)
         rect = rect.Intersect(inState.mMask->GetRect());
      target = inTarget.ClipRect(rect);
   }
   else
   {
      target = inTarget;
   }

   HardwareContext *hardware = target.IsHardware() ? target.mHardware : 0;

   for(int l=0;l<mLines.size();l++)
   {
      Line &line = mLines[l];
      int chars = line.mChars;
      int done  = 0;
      int gid = line.mCharGroup0;
      CharGroup *group = &mCharGroups[gid++];
      int y0 = line.mY0 + line.mMetrics.ascent;
      if (y0>target.mRect.h) break;

      int c0 = line.mCharInGroup0;
      int x = 0;
      // Get alignment...
      int extra = (mRect.w - line.mMetrics.width);
      switch(group->mFormat->align(tfaLeft))
      {
         case tfaLeft: break;
         case tfaCenter: x+=extra/2; break;
         case tfaRight: x+=extra; break;
      }

      while(done<chars)
      {
         int left = std::min(group->mChars - c0,chars-done);
         while(left==0)
         {
            group = &mCharGroups[gid++];
            c0 = 0;
            left = std::min(group->mChars,chars-done);
         }
         done += left;
         if (group->mString && group->mFont)
         {
            uint32 group_tint =
                 inState.mColourTransform->Transform(group->mFormat->color(textColor) | 0xff000000);
            // Now render the chars ...
            for(int c=0;c<left;c++)
            {
               int advance = 10;
               int ch = group->mString[c+c0];
               if (ch!='\n')
               {
                  Tile tile = group->mFont->GetGlyph( group->mString[c+c0], advance );
                  UserPoint p = origin + dPdX*x + dPdY*y0+ UserPoint(tile.mOx,tile.mOy);
                  if (hardware)
                  {
                     // todo - better to wizz though and do all of the same surface first?
                     // ok to call this multiple times with same data
                     hardware->BeginBitmapRender(tile.mSurface,group_tint);
                     hardware->RenderBitmap(tile.mRect, (int)p.x, (int)p.y);
                  }
                  else
                  {
                     tile.mSurface->BlitTo(target,
                        tile.mRect, (int)p.x, (int)p.y,
                        bmTinted, 0,
                       (uint32)group->mFormat->color | 0xff000000);
                  }
                  x+= advance;
                  if (x>last_x)
                     break;
               }
            }
         }
         c0 += left;
      }
   }

   if (hardware)
      hardware->EndBitmapRender();

}

void TextField::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap)
{
   UpdateFonts(inTrans);
   Layout();
   if (0 && inForBitmap)
   {
      // TODO: actual text extent (if not backgroundColor )
      //       borders
   }
   else
   {
      for(int corner=0;corner<4;corner++)
      {
            double x = mRect.x + ((corner & 1) ? mRect.w : 0);
            double y = mRect.y + ((corner & 2) ? mRect.h : 0);
            outExt.Add( inTrans.mMatrix->Apply(x,y) );
      }
   }
}



void TextField::Layout()
{
   if (!mLinesDirty)
      return;

   mLines.resize(0);
   int y0 = 0;
   Line line;
   line.mY0 = y0;
   int char_count = 0;
   int height = 0;
   int width = 0;
   int x = 0;
   int y = 0;

   for(int i=0;i<mCharGroups.size();i++)
   {
      CharGroup &g = mCharGroups[i];
      int cid = 0;
      int last_word_cid = 0;
      int last_word_x = x;
      int last_word_line_chars = line.mChars;
      if (g.mNewLines>0 && multiline)
      {
         if (line.mChars)
         {
            g.UpdateMetrics(line.mMetrics);
            mLines.push_back(line);
            y += line.mMetrics.height + (g.mNewLines-1) * g.Height();
            line.Clear();
         }
         else
            y += (g.mNewLines) * g.Height();

         x = 0;
         line.mY0 = y;
         line.mChar0 = char_count;
         line.mCharGroup0 = i;
         line.mCharInGroup0 = cid;
      }


      g.UpdateMetrics(line.mMetrics);
      while(cid<g.mChars)
      {
         if (line.mChars==0)
         {
            x = 0;
            line.mY0 = y;
            line.mChar0 = char_count;
            line.mCharGroup0 = i;
            line.mCharInGroup0 = cid;
            last_word_line_chars = 0;
            last_word_cid = cid;
            last_word_x = 0;
         }

         int advance = 0;
         int ch = g.mString[cid];
         line.mChars++;
         char_count++;
         cid++;
         if ( !isalpha(ch) && !isdigit(ch) && ch!='_' )
         {
            if (isspace(ch) || line.mChars==1)
            {
               last_word_cid = cid;
               last_word_line_chars = line.mChars;
            }
            else
            {
               last_word_cid = cid-1;
               last_word_line_chars = line.mChars-1;
            }
            last_word_x = x;
         }

         if (ch=='\n')
         {
            // New line ...
            mLines.push_back(line);
            line.Clear();
            g.UpdateMetrics(line.mMetrics);
            y += g.Height();
            continue;
         }

         int ox = x;
         g.mFont->GetGlyph( ch, advance );
         x+= advance;
         //printf(" Char %c (%d..%d,%d)\n", ch, ox, x, y);
         if (wordWrap && (x > mRect.w) && line.mChars>1)
         {
            // No break on line so far - just back up 1 character....
            if (last_word_line_chars==0)
            {
               cid--;
               line.mChars--;
               char_count--;
               line.mMetrics.width = ox;
            }
            else
            {
               // backtrack to last break ...
               cid = last_word_cid;
               char_count-= line.mChars - last_word_line_chars;
               line.mChars = last_word_line_chars;
               line.mMetrics.width = last_word_x;
            }
            mLines.push_back(line);
            y += g.Height();
            x = 0;
            line.Clear();
            g.UpdateMetrics(line.mMetrics);
            continue;
         }

         line.mMetrics.width = x;
         if (x>width)
            width = x;
      }
   }
   if (line.mChars)
   {
      mCharGroups[mCharGroups.size()-1].UpdateMetrics(line.mMetrics);
      y += line.mMetrics.height;
      mLines.push_back(line);
   }

   height = y;

   if (autoSize != asNone)
   {
      if (!wordWrap)
         mRect.w = width;
      mRect.h = height;
   }

   mLinesDirty = false;
}


// --- TextFormat -----------------------------------

TextFormat::TextFormat() :
   align(tfaLeft),
   blockIndent(0),
   bold(false),
   bullet(false),
   color(0x00000000),
   font(L"Times"),
   indent(0),
   italic(false),
   kerning(false),
   leading(0),
   leftMargin(0),
   letterSpacing(0),
   rightMargin(0),
   size(12),
   tabStops( QuickVec<int>() ),
   target(L""),
   underline(false),
   url(L"")
{
}

TextFormat::~TextFormat()
{
}

TextFormat *TextFormat::COW()
{
   if (mRefCount<2)
      return this;
   TextFormat *result = new TextFormat(*this);
   result->mRefCount = 1;
   mRefCount --;
   return result;
}

TextFormat *TextFormat::Create(bool inInitRef)
{
   TextFormat *result = new TextFormat();
   if (inInitRef)
      result->IncRef();
   return result;
}

static TextFormat *sDefaultTextFormat = 0;

TextFormat *TextFormat::Default()
{
   if (!sDefaultTextFormat)
      sDefaultTextFormat = TextFormat::Create(true);
   sDefaultTextFormat->IncRef();
   return sDefaultTextFormat;
}



// --- TextFormat -----------------------------------

void CharGroup::Clear()
{
   delete [] mString;
   mFormat->DecRef();
   if (mFont)
      mFont->DecRef();
}

bool CharGroup::UpdateFont(double inScale,GlyphRotation inRotation,bool inNative)
{
   int h = 0.5 + inScale*mFormat->size;
   if (!mFont || h!=mFontHeight || mFont->IsNative()!=inNative)
   {
      if (mFont)
         mFont->DecRef();
      mFont = Font::Create(*mFormat,inScale,inRotation,inNative,true);
      mFontHeight = h;
      return true;
   }
   return false;
}


} // end namespace nme

