#include <TextField.h>


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
	mCharGroups.push_back(chars);
	mLinesDirty = true;
}

bool TextField::Render( const RenderTarget &inTarget, const RenderState &inState )
{
	// Update fonts ...
	for(int i=0;i<mCharGroups.size();i++)
		mCharGroups[i].UpdateFont(inState);
	return true;
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
   url(L""),
	mRefCount(0)
{
}

TextFormat::~TextFormat()
{
}

TextFormat *TextFormat::IncRef()
{
	mRefCount++;
	return this;
}

void TextFormat::DecRef()
{
	mRefCount--;
	if (mRefCount<=0)
		delete this;
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
}



