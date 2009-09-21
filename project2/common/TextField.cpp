#include <TextField.h>
#include <Tilesheet.h>
#include <Utils.h>
#include <Surface.h>
#include "XML/tinyxml.h"
#include <ctype.h>

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
	type(tftDynamic),
	useRichTextClipboard(false),
	wordWrap(false)
{
	mStringState = ssText;
	mLinesDirty = false;
	mGfxDirty = true;
   mRect = Rect(100,100);
}

TextField::~TextField()
{
	defaultTextFormat->DecRef();
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
	mGfxDirty = true;
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


void TextField::Render( const RenderTarget &inTarget, const RenderState &inState )
{
	for(int i=0;i<mCharGroups.size();i++)
	   if (mCharGroups[i].UpdateFont(inState,!embedFonts))
			mLinesDirty = true;

	Layout();

	Graphics &gfx = GetGraphics();
	if (mGfxDirty)
	{
		gfx.clear();
		int b=2;
		if (background)
		{
			gfx.beginFill( backgroundColor.ival, 1.0 );
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

   int tx = (int)inState.mTransform.mMatrix->mtx;
   int ty = (int)inState.mTransform.mMatrix->mty;
   RenderTarget target = inTarget.ClipRect( mRect.Translated(tx,ty).Intersect(inState.mClipRect) );

	for(int l=0;l<mLines.size();l++)
	{
		Line &line = mLines[l];
		int chars = line.mChars;
		int done  = 0;
		int gid = line.mCharGroup0;
		CharGroup *group = &mCharGroups[gid++];
		int y0 = ty + mRect.y + line.mY0 + line.mMetrics.ascent;
		if (y0>target.mRect.y1())
         break;
		int c0 = line.mCharInGroup0;
	   int x = tx + mRect.x;
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
				// Now render the chars ...
				for(int c=0;c<left;c++)
				{
					int advance = 10;
					int ch = group->mString[c+c0];
					if (ch!='\n')
					{
					   Tile tile = group->mFont->GetGlyph( group->mString[c+c0], advance );
					   tile.mSurface->BlitTo(target, tile.mRect, x+(int)tile.mOx, y0+(int)tile.mOy,
						     (uint32)group->mFormat->color | 0xff000000, true);
					   x+= advance;
					   if (x>target.mRect.x1())
						   break;
					}
				}
			}
			c0 += left;
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

bool CharGroup::UpdateFont(const RenderState &inState,bool inNative)
{
	double scale = inState.mTransform.mMatrix->GetScaleY() *
					   inState.mTransform.mStageScaleY;
	int h = 0.5 + scale*mFormat->size;
	if (!mFont || h!=mFontHeight || mFont->IsNative()!=inNative)
	{
		if (mFont)
			mFont->DecRef();
		mFont = Font::Create(*mFormat,scale,inNative,true);
	   mFontHeight = h;
		return true;
	}
	return false;
}



