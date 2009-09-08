#include <TextField.h>
#include <Tilesheet.h>
#include <Utils.h>
#include "XML/tinyxml.h"


TextField::TextField() :
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
	x = 0;
	y = 0;
	width = 100;
	height = 100;
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
	chars.mChar0 = 0;
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
	      chars.mChar0 = ioCharCount;
	      chars.mChars = len;
	      chars.mNewLines = inLineSkips;
			ioCharCount += len;

	      mCharGroups.push_back(chars);
		   printf(" %s %d\n", text->Value(), inLineSkips );
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


bool TextField::Render( const RenderTarget &inTarget, const RenderState &inState )
{
	Layout();

	if (mGfxDirty)
	{
		mGfx.clear();
		if (background)
		{
			mGfx.beginFill( backgroundColor.ival, 1.0 );
			mGfx.moveTo(x,y);
			mGfx.lineTo(x+width,y);
			mGfx.lineTo(x+width,y+height);
			mGfx.lineTo(x,y+height);
			mGfx.lineTo(x,y);
		}
		mGfxDirty = false;
	}

		if (!mGfx.empty())
	{
	   mGfx.Render(inTarget,inState);
	}

	// Update fonts ...
	int x = this->x;
	int y = this->y;
	for(int i=0;i<mCharGroups.size();i++)
	{
		CharGroup &g = mCharGroups[i];
		if (!g.mString)
			continue;
		g.UpdateFont(inState);
		if (!g.mFont)
			continue;
		// Now render the chars ...
      for(int c=0;c<g.mChars;c++)
		{
			int advance = 10;
			Tile tile = g.mFont->GetGlyph( g.mString[c], advance );
         tile.mSurface->BlitTo(inTarget, tile.mRect, x+(int)tile.mOx, y+(int)tile.mOy,
              (uint32)g.mFormat->color | 0xff000000, true);
         x+= advance;
		}
	}

	return true;
}


void TextField::Layout()
{
	if (!mLinesDirty)
		return;


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

void CharGroup::UpdateFont(const RenderState &inState)
{
	double scale = inState.mTransform.mMatrix.GetScaleY() *
					   inState.mTransform.mStageScaleY;
	int h = 0.5 + scale*mFormat->size;
	if (!mFont || h!=mFontHeight)
	{
		if (mFont)
			mFont->DecRef();
		mFont = Font::Create(*mFormat,scale,true);
	   mFontHeight = h;
	}
}



